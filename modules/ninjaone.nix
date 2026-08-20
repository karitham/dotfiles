# NixOS module: NinjaOne RMM agent (runtime-extracted .deb, auto-updating).
#
# Bootstrap
# ---------
# The agent ships as a portal-generated .deb that is also the device
# identity: it embeds server.conf/agent.conf (ClientUID, NodeId, V2AgentKey,
# MachineId).  It is kept OUT of the Nix store and extracted at boot into
# ${dataDir}/root by the ninjarmm-install oneshot, which also applies the
# upstream post-install steps (cert bundle, root ownership).  The agent
# service runs the upstream binary with the NixOS dynamic loader + explicit
# library path and DAEMON_RUN=1 (foreground), bind-mounting the extracted tree
# at /opt/NinjaRMMAgent so the agent's hardcoded absolute paths resolve.
#
# Because the .deb carries the device identity it cannot be shared between
# machines: each machine needs its own installer, generated in the portal.
# The .deb is only needed for the initial install; after that, updates never
# touch the portal.
#
# Updating
# --------
# The agent's self-update (patcher) cannot work on NixOS: it spawns gunzip by
# name (PATH), resolves its own location via /proc/self/exe (the ld-linux
# wrapper -> /nix/store), and the binaries it downloads are Debian ELFs.
# Instead, on every boot ninjarmm-install checks the public version manifest:
#
#   1. Derive the manifest URL from Host/ClientUID in the extracted
#      server.conf (no portal auth, region-agnostic):
#        https://$Host/ws/agent/version/LINUX/$ClientUID/0
#   2. Compare the manifest's version against the extracted
#      ninjarmm-linagent.manifest.
#   3. If newer: download agent_url, verify against agent_sha256, then
#      atomically replace the binary + manifest (a running agent keeps its
#      old inode; a non-atomic overwrite would SIGBUS it).
#
# The check is best-effort: any failure (offline, manifest error, checksum
# mismatch) logs and keeps the current version, so the agent always starts.
#
#   - force a check without rebooting:  systemctl restart ninjarmm-install
#   - disable checks:                    services.ninjaone.autoUpdate = false
#
# Caveat: checks only run at boot (or manual restart), so a machine that
# stays up for months will not self-update until it reboots.
#
# Security
# --------
# The agent runs under a hard systemd sandbox (see ninjarmm-agent
# serviceConfig): resource caps, read-only OS tree, no home/devices, no
# capabilities, restricted address families, and ProtectProc=invisible so it
# cannot read other processes.  /proc/cpuinfo, /proc/meminfo and /proc/stat
# stay visible, so CPU/mem/load telemetry still reaches the portal.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ninjaone;

  # The upstream binary is a Debian ELF with PT_INTERP=/lib64/ld-linux-x86-64.so.2,
  # so it is launched via the NixOS loader with an explicit library path.
  ldLibraryPath = lib.makeLibraryPath (
    [
      pkgs.gcc.cc.lib
      pkgs.glibc
      pkgs.libglvnd
      pkgs.libxkbcommon
      pkgs.mesa
      pkgs.libX11
      pkgs.libXext
      pkgs.libxcb
    ]
    ++ cfg.extraLibraries
  );

  agentBinary = "${cfg.dataDir}/root/${cfg.agentBinaryRelativePath}";

  installScript = pkgs.writeShellScript "ninjarmm-install" ''
    set -euo pipefail

    installerPath="${cfg.installerPath}"
    rootDir="${cfg.dataDir}/root"
    marker="$rootDir/.extracted"
    unitsDir="${cfg.dataDir}/systemd"
    programfiles="$rootDir/opt/NinjaRMMAgent/programfiles"
    configDir="$programfiles/config"
    autoUpdate="${toString cfg.autoUpdate}"

    if [ ! -f "$installerPath" ]; then
      echo "NinjaOne installer not found at $installerPath" >&2
      exit 1
    fi

    # The agent's distress monitor checks for its upstream systemd units
    # at /lib/systemd/system, which does not exist on NixOS.  Keep the
    # units in $unitsDir (survives rebuilds) and let ninjarmm-agent
    # bind-mount the directory there.  /etc/systemd/system cannot be
    # used for this: it is /etc/static/systemd/system on NixOS and is
    # regenerated on every rebuild.
    sync_units() {
      mkdir -p "$unitsDir"
      cp -f "$rootDir/tmp/ninja-startup/ninjarmm-agent.service" "$unitsDir/"
      cp -f "$rootDir/tmp/ninja-startup/ninjarmm-patcher.service" "$unitsDir/"
      cp -f "$rootDir/tmp/ninja-startup/ninjarmm-patcher.timer" "$unitsDir/"
      cp -f "$rootDir/tmp/ninja-uninstall/ninjarmm-deb-uninstall.service" "$unitsDir/ninjarmm-uninstall.service"
    }

    # Version bump: fetch the public version manifest (no auth) and apply a
    # newer agent when one exists.  Best-effort: any failure (offline,
    # manifest error, checksum mismatch) is logged and keeps the current
    # version; it must never block the agent from starting.
    check_for_updates() {
      [ "$autoUpdate" = "true" ] || return 0
      [ -f "$configDir/server.conf" ] || {
        echo "NinjaOne update: no server.conf; skipping." >&2
        return 0
      }

      host="$(${pkgs.gnused}/bin/sed -n 's/^Host=\(.*\)$/\1/p' "$configDir/server.conf")"
      clientUid="$(${pkgs.gnused}/bin/sed -n 's/^ClientUID=\(.*\)$/\1/p' "$configDir/server.conf")"
      if [ -z "$host" ] || [ -z "$clientUid" ]; then
        echo "NinjaOne update: cannot parse Host/ClientUID from server.conf; skipping." >&2
        return 0
      fi

      workDir="$(mktemp -d)"
      if ! ${pkgs.curl}/bin/curl -fsS -m 20 \
          "https://$host/ws/agent/version/LINUX/$clientUid/0" \
          -o "$workDir/manifest.json" 2>/dev/null; then
        echo "NinjaOne update: manifest fetch failed; skipping (will retry next boot)." >&2
        rm -rf "$workDir"
        return 0
      fi

      latestVersion="$(${pkgs.gnused}/bin/sed -n 's/.*"version":"\([^"]*\)".*/\1/p' "$workDir/manifest.json")"
      agentUrl="$(${pkgs.gnused}/bin/sed -n 's/.*"agent_url":"\([^"]*\)".*/\1/p' "$workDir/manifest.json")"
      agentSha256="$(${pkgs.gnused}/bin/sed -n 's/.*"agent_sha256":"\([^"]*\)".*/\1/p' "$workDir/manifest.json")"
      installedVersion="$(${pkgs.gnused}/bin/sed -n 's/^Version=\(.*\)$/\1/p' "$programfiles/ninjarmm-linagent.manifest")"

      if [ -z "$latestVersion" ] || [ -z "$agentUrl" ] || [ -z "$agentSha256" ]; then
        echo "NinjaOne update: manifest fields missing; skipping." >&2
        rm -rf "$workDir"
        return 0
      fi

      if [ "$latestVersion" = "$installedVersion" ]; then
        echo "NinjaOne agent is up to date ($installedVersion)."
        rm -rf "$workDir"
        return 0
      fi

      echo "NinjaOne update available: $installedVersion -> $latestVersion; downloading..."
      if ! ${pkgs.curl}/bin/curl -fsS -m 120 -o "$workDir/agent.tgz" "$agentUrl" 2>/dev/null; then
        echo "NinjaOne update: download failed; keeping current version." >&2
        rm -rf "$workDir"
        return 0
      fi

      echo "$agentSha256  $workDir/agent.tgz" | ${pkgs.coreutils}/bin/sha256sum -c - >/dev/null 2>&1 || {
        echo "NinjaOne update: checksum mismatch; keeping current version." >&2
        rm -rf "$workDir"
        return 0
      }

      ${pkgs.gzip}/bin/gzip -dc "$workDir/agent.tgz" | ${pkgs.gnutar}/bin/tar -xf - -C "$workDir"

      # Atomic replace: cp -f would truncate the inode a running agent has
      # mapped, crashing it with SIGBUS on the next page fault.  Write to a
      # temp name and rename; the running process keeps its old inode.
      cp -f "$workDir/ninjarmm-linagent" "$programfiles/ninjarmm-linagent.new"
      cp -f "$workDir/ninjarmm-linagent.manifest" "$programfiles/ninjarmm-linagent.manifest.new"
      mv -f "$programfiles/ninjarmm-linagent.new" "$programfiles/ninjarmm-linagent"
      mv -f "$programfiles/ninjarmm-linagent.manifest.new" "$programfiles/ninjarmm-linagent.manifest"
      chown 0:0 "$programfiles/ninjarmm-linagent" "$programfiles/ninjarmm-linagent.manifest"
      rm -rf "$workDir"
      echo "NinjaOne agent updated to $latestVersion."
    }

    if [ -f "$marker" ] && [ "$installerPath" -ot "$marker" ]; then
      sync_units
      check_for_updates
      echo "NinjaOne agent already extracted."
      exit 0
    fi

    # Preserve the registered identity (NodeId/keys in agent.conf and
    # server.conf) across re-extracts so version bumps do not
    # re-register as a new device.  programdata is runtime state and is
    # intentionally not preserved.
    backupDir="$(mktemp -d)"
    if [ -d "$configDir" ]; then cp -a "$configDir" "$backupDir/config"; fi

    echo "Extracting NinjaOne agent from $installerPath..."
    rm -rf "$rootDir"
    mkdir -p "$rootDir"
    ${pkgs.dpkg}/bin/dpkg-deb -x "$installerPath" "$rootDir"

    if [ -d "$backupDir/config" ]; then
      rm -rf "$configDir"
      mkdir -p "$(dirname "$configDir")"
      cp -a "$backupDir/config" "$(dirname "$configDir")/"
    fi
    rm -rf "$backupDir"

    echo "Applying post-install configuration..."
    mkdir -p "$programfiles/config"
    cp -f "$rootDir/tmp/ninja-startup/ninjarmm-curl-ca-bundle.crt" "$programfiles/"

    sync_units
    check_for_updates

    chown -R 0:0 "$rootDir/opt/NinjaRMMAgent"
    chmod 600 "$programfiles/config/agent.conf" "$programfiles/config/server.conf"

    touch "$marker"
    echo "NinjaOne agent extracted to $rootDir."
  '';
in
{
  options.services.ninjaone = {
    enable = lib.mkEnableOption "NinjaOne RMM agent";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/ninjaone";
      description = "Directory where the agent is extracted and keeps state.";
    };

    installerPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/kar/private/ninjaone-agent.deb";
      description = ''
        Runtime path to the NinjaOne <literal>.deb</literal> installer.
        Must be a plain string, not a Nix path literal, or Nix will copy it
        into the store.
        This is the portal-generated installer for this device: it embeds the
        device identity (server.conf/agent.conf), so generate one per machine
        in the portal and do not share it.  It is only needed for the initial
        install; updates are applied automatically (see the module header).
      '';
    };

    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        On every <literal>ninjarmm-install</literal> start (i.e. at boot),
        check the public version manifest and update the agent when a newer
        version exists.  The manifest URL is derived at runtime from
        <literal>Host</literal>/<literal>ClientUID</literal> in
        <literal>server.conf</literal>, so no portal access or manual steps
        are needed; the downloaded tarball is verified against the manifest's
        SHA-256 before being applied.
      '';
    };

    agentBinaryRelativePath = lib.mkOption {
      type = lib.types.str;
      default = "opt/NinjaRMMAgent/programfiles/ninjarmm-linagent";
      description = "Path inside the extracted .deb root to the agent executable.";
    };

    extraLibraries = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages whose <literal>/lib</literal> is added to the agent's library path.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isx86_64;
        message = "services.ninjaone is only supported on x86_64-linux.";
      }
      {
        assertion = !(lib.hasPrefix "/nix/store/" cfg.installerPath);
        message = "services.ninjaone.installerPath must not point into the Nix store.";
      }
    ];

    systemd.services.ninjarmm-install = {
      description = "Install/Update NinjaOne RMM agent";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "local-fs.target"
      ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "ninjaone";
        ExecStart = installScript;
      };
    };

    # The agent expects a ninjarmm-* unit set: its patcher script
    # systemctl-enables ninjarmm-patcher.timer and it looks for
    # ninjarmm-agent to detect how it is managed.  Declare no-op units here
    # rather than writing them to /etc/systemd/system at runtime — that path
    # is regenerated per rebuild and is read-only with
    # system.immutable.enable.  NixOS pre-enables them, so the agent's own
    # `systemctl enable` calls are idempotent no-ops that need no /etc write
    # access under ProtectSystem=full.
    systemd.services.ninjarmm-patcher = {
      description = "NinjaOne patcher (no-op on NixOS; updates applied by ninjarmm-install's manifest check)";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/true";
      };
    };

    systemd.timers.ninjarmm-patcher = {
      description = "Timer for ninjarmm-patcher.service (no-op on NixOS)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Unit = "ninjarmm-patcher.service";
        OnUnitActiveSec = "7d";
      };
    };

    systemd.services.ninjarmm-agent = {
      description = "NinjaOne RMM Agent";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "ninjarmm-install.service"
      ];
      wants = [
        "network-online.target"
        "ninjarmm-install.service"
      ];

      # NixOS turns this into both Path= and the service $PATH (via
      # Environment=PATH).  A raw Path= inside serviceConfig is ignored
      # because NixOS already sets Environment=PATH, which systemd gives
      # precedence over ExecSearchPath/Path=.  The agent shells out to these
      # by name for its monitoring worker, so they must be on $PATH.  NixOS
      # appends its default set (coreutils, findutils, gnugrep, gnused,
      # systemd) automatically.
      #
      # This is the "stats-ok" half of the access trim: tools needed for
      # CPU/mem/disk/network/hardware telemetry.  Deliberately absent are the
      # process-introspection tools (top/ps/lsof) — the process list stays
      # hidden from the agent even though procps ships top alongside free.
      path = [
        pkgs.gzip
        pkgs.gnutar
        pkgs.which
        pkgs.bash
        pkgs.gawk
        pkgs.procps
        pkgs.util-linux
        pkgs.hostname
        pkgs.dmidecode
        pkgs.net-tools
      ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.glibc}/lib/ld-linux-x86-64.so.2 --library-path ${ldLibraryPath} ${agentBinary}";
        Restart = "always";
        RestartSec = 10;
        # The agent ignores SIGTERM for ~70s before exiting on its own,
        # which stalls every rebuild.  Its state is on disk and it reconnects
        # on start, so kill it hard after a short grace period.
        TimeoutStopSec = "3s";
        WorkingDirectory = "${cfg.dataDir}";
        StateDirectory = "ninjaone";
        BindPaths = [
          "${cfg.dataDir}/root/opt/NinjaRMMAgent:/opt/NinjaRMMAgent"
          "${cfg.dataDir}/systemd:/lib/systemd/system"
        ];

        # Resource limits.  The agent is effectively idle (a few hundred ms
        # CPU / ~30MB RAM per hour), so these caps bound worst-case behaviour
        # without interfering with check-ins.
        CPUQuota = "25%";
        MemoryMax = "256M";
        MemoryHigh = "128M";
        TasksMax = "128";
        Nice = 10;
        IOSchedulingClass = "idle";

        # Filesystem: /usr /boot /etc read-only; no home dirs; private /tmp.
        # ProtectSystem=full (not =strict) is deliberate: =strict + BindPaths
        # is documented to break the bind mounts the agent writes through.
        ProtectSystem = "full";
        ProtectHome = true;
        PrivateTmp = true;
        # Sensitive files made fully inaccessible.  Only list paths that
        # exist on the system: systemd refuses to set up the namespace if an
        # InaccessiblePaths entry is missing (NixOS has no /etc/gshadow).
        InaccessiblePaths = [
          "/etc/shadow"
          "/etc/ssh"
          "/var/lib/private"
          "/var/lib/systemd/coredump"
        ];

        # Kernel/device hardening.
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RestrictRealtime = true;
        NoNewPrivileges = true;
        SystemCallArchitectures = "native";

        # Process privacy: ProtectProc=invisible hides other processes' /proc
        # entries while /proc/cpuinfo, /proc/meminfo and /proc/stat remain
        # visible, so CPU/mem/load telemetry still reaches the portal.
        ProtectProc = "invisible";

        # No capabilities at all: the agent only does network, D-Bus and
        # read-only /proc//sys, none of which need them.
        CapabilityBoundingSet = "";

        # @system-service default, minus process-introspection syscalls.
        SystemCallFilter = [
          "@system-service"
          "~ptrace"
          "~process_vm_readv"
          "~process_vm_writev"
        ];

        # Network: TLS to NinjaOne, D-Bus/systemctl over AF_UNIX, netlink for
        # interface discovery.  Nothing else.
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
      };
      environment = {
        DAEMON_RUN = "1";
        LC_ALL = "C";
        # Keep Qt's user-level QSettings writes inside the state dir instead
        # of the filesystem root.
        HOME = "${cfg.dataDir}";
      };
    };
  };
}
