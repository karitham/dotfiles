# NixOS module: NinjaOne RMM agent (client install, runtime-extracted .deb).
#
# Design
# ------
# The agent .deb is kept OUT of the Nix store and extracted at boot into
# ${dataDir}/root by the ninjaone-install oneshot, which also applies the
# upstream post-install steps (cert bundle, root ownership).  The agent
# service runs the upstream binary with the NixOS dynamic loader + explicit
# library path and DAEMON_RUN=1 (foreground), bind-mounting the extracted tree
# at /opt/NinjaRMMAgent so the agent's hardcoded absolute paths resolve.
#
# Upgrading
# ---------
# The agent's self-update (patcher) cannot work on NixOS: it spawns gunzip by
# name (PATH), resolves its own location via /proc/self/exe (the ld-linux
# wrapper -> /nix/store), and the binaries it downloads are Debian ELFs.
# Version bumps are therefore manual, but do not need the portal:
#
#   1. Query the public version manifest for the current release (no auth):
#        curl https://agent-us2.us2.ninjarmm.com/ws/agent/version/LINUX/<clientUid>/0
#      (clientUid is in programfiles/config/server.conf; the region in the
#      hostname may differ).  Note agent_url and agent_sha256.
#
#   2. Download and verify the agent tarball:
#        curl -o ~/private/ninjaone-agent.tgz <agent_url>
#        echo '<agent_sha256>  ~/private/ninjaone-agent.tgz' | sha256sum -c -
#      If you set services.ninjaone.updaterSha256, update it to agent_sha256.
#
#   3. Rebuild; ninjaone-install overlays the tarball over the extracted tree
#      when it is newer than the .deb.
#
# Security
# --------
# The agent runs under a hard systemd sandbox (see ninjaone-agent
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

  # No-op units installed by apply_fixups so the agent's upstream
  # ninja-systemd-patcher.sh succeeds without enabling a real patcher.
  # Kept as writeText (not heredocs in the shell script) to avoid the Nix
  # ''-string indentation trap with heredoc terminators.
  patcherServiceUnit = pkgs.writeText "ninjarmm-patcher.service" ''
    [Unit]
    Description=NinjaOne patcher (no-op on NixOS; updates are applied by ninjaone-install)

    [Service]
    Type=oneshot
    ExecStart=${pkgs.coreutils}/bin/true
  '';

  patcherTimerUnit = pkgs.writeText "ninjarmm-patcher.timer" ''
    [Unit]
    Description=Timer for ninjarmm-patcher.service (no-op on NixOS)

    [Timer]
    Unit=ninjarmm-patcher.service
    OnUnitActiveSec=7d

    [Install]
    WantedBy=timers.target
  '';

  installScript = pkgs.writeShellScript "ninjaone-install" ''
    set -euo pipefail

    installerPath="${cfg.installerPath}"
    rootDir="${cfg.dataDir}/root"
    marker="$rootDir/.extracted"
    unitsDir="${cfg.dataDir}/systemd"
    updaterPath="${cfg.updaterPath}"
    updaterSha256="${toString cfg.updaterSha256}"

    if [ ! -f "$installerPath" ]; then
      echo "NinjaOne installer not found at $installerPath" >&2
      exit 1
    fi

    # The agent's distress monitor checks for its upstream systemd units
    # at /lib/systemd/system, which does not exist on NixOS.  Keep the
    # units in $unitsDir (survives rebuilds) and let ninjaone-agent
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

    # Version bump: overlay the current agent tarball over the extracted
    # tree when it is newer than the .deb, so an old tarball can never
    # downgrade a fresh installer.
    apply_updater() {
      [ -f "$updaterPath" ] || return 0
      [ "$updaterPath" -nt "$installerPath" ] || return 0

      if [ -n "$updaterSha256" ]; then
        echo "Verifying updater SHA-256..."
        echo "$updaterSha256  $updaterPath" | sha256sum -c - || {
          echo "Updater checksum mismatch; refusing to apply." >&2
          exit 1
        }
      fi

      echo "Applying agent updater from $updaterPath..."
      tmpUpd="$(mktemp -d)"
      ${pkgs.gzip}/bin/gzip -dc "$updaterPath" | ${pkgs.gnutar}/bin/tar -xf - -C "$tmpUpd"
      programfiles="$rootDir/opt/NinjaRMMAgent/programfiles"

      # Atomic replace: cp -f would truncate the inode the running agent has
      # mapped, crashing it with SIGBUS on the next page fault.  Write to a
      # temp name and rename; the running process keeps its old inode.
      cp -f "$tmpUpd/ninjarmm-linagent" "$programfiles/ninjarmm-linagent.new"
      cp -f "$tmpUpd/ninjarmm-linagent.manifest" "$programfiles/ninjarmm-linagent.manifest.new"
      mv -f "$programfiles/ninjarmm-linagent.new" "$programfiles/ninjarmm-linagent"
      mv -f "$programfiles/ninjarmm-linagent.manifest.new" "$programfiles/ninjarmm-linagent.manifest"
      chown 0:0 "$programfiles/ninjarmm-linagent" "$programfiles/ninjarmm-linagent.manifest"
      rm -rf "$tmpUpd"
      echo "Applied agent updater: $(grep '^Version=' "$programfiles/ninjarmm-linagent.manifest" || true)"
    }

    # Keep the agent's own systemd integration from misfiring.  The
    # agent re-deploys ninja-systemd-patcher.sh from its embedded .qrc
    # when the file differs, so patching that script cannot work;
    # instead we make the upstream script succeed.  It
    # systemctl-enables and -starts ninjarmm-patcher.timer, which the
    # manager can only see if the units live in a host-visible path
    # (/etc/systemd/system).  Install no-op units and pre-enable them
    # from here (this service runs unlocked), so the agent's own
    # `systemctl enable` is an idempotent no-op that needs no /etc
    # write access under ProtectSystem=full.
    apply_fixups() {
      mkdir -p /etc/systemd/system

      cp -f "${patcherServiceUnit}" /etc/systemd/system/ninjarmm-patcher.service
      cp -f "${patcherTimerUnit}" /etc/systemd/system/ninjarmm-patcher.timer

      ${pkgs.systemd}/bin/systemctl daemon-reload || true
      ${pkgs.systemd}/bin/systemctl enable ninjarmm-patcher.timer ninjarmm-patcher.service || true
      ${pkgs.systemd}/bin/systemctl start ninjarmm-patcher.timer || true

      # The agent looks for its own unit (ninjarmm-agent) to detect how
      # it is managed; alias our unit so those checks pass.
      mkdir -p /etc/systemd/system/multi-user.target.wants
      ln -sf ../ninjaone-agent.service /etc/systemd/system/multi-user.target.wants/ninjarmm-agent.service
      ln -sf ninjaone-agent.service /etc/systemd/system/ninjarmm-agent.service
    }

    if [ -f "$marker" ] && [ "$installerPath" -ot "$marker" ]; then
      sync_units
      apply_updater
      apply_fixups
      echo "NinjaOne agent already extracted and up to date."
      exit 0
    fi

    # Preserve the registered identity (NodeId/keys in agent.conf and
    # server.conf) across re-extracts so version bumps do not
    # re-register as a new device.  programdata is runtime state and is
    # intentionally not preserved.
    configDir="$rootDir/opt/NinjaRMMAgent/programfiles/config"
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
    programfiles="$rootDir/opt/NinjaRMMAgent/programfiles"
    mkdir -p "$programfiles/config"
    cp -f "$rootDir/tmp/ninja-startup/ninjarmm-curl-ca-bundle.crt" "$programfiles/"

    sync_units
    apply_updater
    apply_fixups

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
        into the store.  Download it from the NinjaOne portal.
      '';
    };

    updaterPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/kar/private/ninjaone-agent.tgz";
      description = ''
        Runtime path to the current agent updater tarball (ninjarmm-linagent +
        manifest, served publicly; see the module header for how to fetch it).  When
        newer than the installer <literal>.deb</literal>, ninjaone-install
        overlays it over the extracted tree.  Must be a plain string, not a
        Nix path literal, to stay out of the store.
      '';
    };

    updaterSha256 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional SHA-256 of the updater tarball (<literal>agent_sha256</literal>
        from the version manifest).  When set, ninjaone-install verifies the
        tarball before overlaying it, so a corrupted or tampered download
        fails loudly instead of installing.
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

    systemd.services.ninjaone-install = {
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

    systemd.services.ninjaone-agent = {
      description = "NinjaOne RMM Agent";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "ninjaone-install.service"
      ];
      wants = [
        "network-online.target"
        "ninjaone-install.service"
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
