# NixOS module for a NinjaOne RMM client agent install.
#
# The agent binary and .deb are kept OUT of the Nix store.  The .deb is expected
# at a runtime path outside the store (default ~/private/ninjaone-agent.deb).
# At boot a oneshot service extracts it into /var/lib/ninjaone/root and applies
# the upstream post-install steps (cert bundle, MachineId, root ownership).  The
# agent service then runs the upstream binary with the NixOS dynamic linker, an
# explicit library path, and the upstream DAEMON_RUN=1 environment so the agent
# stays in the foreground.  The extracted tree is bind-mounted at
# /opt/NinjaRMMAgent so hardcoded absolute paths resolve.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ninjaone;

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
in
{
  options.services.ninjaone = {
    enable = lib.mkEnableOption "NinjaOne RMM agent (client install, runtime-extracted .deb)";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/ninjaone";
      description = "Directory where the agent is extracted and keeps state.";
    };

    installerPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.my.username}/private/ninjaone-agent.deb";
      defaultText = lib.literalExpression ''"''${config.my.username}/private/ninjaone-agent.deb"'';
      description = ''
        Runtime path to the NinjaOne <literal>.deb</literal> installer.
        Must be a plain string, not a Nix path literal, otherwise Nix will copy
        the package into the store.  Download the installer manually from the
        NinjaOne portal and place it at this path.
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
      description = "Extra packages whose <literal>/lib</literal> directories are added to the agent's library path.";
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
        message = "services.ninjaone.installerPath must not point into the Nix store; the .deb must stay outside the store.";
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
        ExecStart = pkgs.writeShellScript "ninjaone-install" (''
          set -euo pipefail

          installerPath="${cfg.installerPath}"
          rootDir="${cfg.dataDir}/root"
          marker="$rootDir/.extracted"

          if [ ! -f "$installerPath" ]; then
            echo "NinjaOne installer not found at $installerPath" >&2
            exit 1
          fi

          if [ -f "$marker" ] && [ "$installerPath" -ot "$marker" ]; then
            echo "NinjaOne agent already extracted and up to date."
            exit 0
          fi

          echo "Extracting NinjaOne agent from $installerPath..."
          rm -rf "$rootDir"
          mkdir -p "$rootDir"
          ${pkgs.dpkg}/bin/dpkg-deb -x "$installerPath" "$rootDir"

          echo "Applying post-install configuration..."
          programfiles="$rootDir/opt/NinjaRMMAgent/programfiles"
          mkdir -p "$programfiles/config"
          cp -f "$rootDir/tmp/ninja-startup/ninjarmm-curl-ca-bundle.crt" "$programfiles/"
          machineId="$(cat /etc/machine-id 2>/dev/null || echo "")"
          sed -i "/^MachineId/ s#=.*#=$machineId#" "$programfiles/config/agent.conf"

          # The agent's distress monitor checks that the upstream systemd units
          # exist.  Copy them (unmodified) into /etc/systemd/system; we do not
          # enable them because their ExecStart won't work on NixOS unpatched.
          mkdir -p /etc/systemd/system
          cp -f "$rootDir/tmp/ninja-startup/ninjarmm-agent.service" /etc/systemd/system/
          cp -f "$rootDir/tmp/ninja-startup/ninjarmm-patcher.service" /etc/systemd/system/
          cp -f "$rootDir/tmp/ninja-startup/ninjarmm-patcher.timer" /etc/systemd/system/
          cp -f "$rootDir/tmp/ninja-uninstall/ninjarmm-deb-uninstall.service" /etc/systemd/system/ninjarmm-uninstall.service
          ${pkgs.systemd}/bin/systemctl daemon-reload || true

          chown -R 0:0 "$rootDir/opt/NinjaRMMAgent"
          chmod 600 "$programfiles/config/agent.conf" "$programfiles/config/server.conf"

          touch "$marker"
          echo "NinjaOne agent extracted to $rootDir."
        '');
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
      serviceConfig = {
        Type = "simple";
        ConditionPathExists = agentBinary;
        ExecStart = "${pkgs.glibc}/lib/ld-linux-x86-64.so.2 --library-path ${ldLibraryPath} ${agentBinary}";
        Restart = "always";
        RestartSec = 10;
        WorkingDirectory = "${cfg.dataDir}";
        StateDirectory = "ninjaone";
        BindPaths = [ "${cfg.dataDir}/root/opt/NinjaRMMAgent:/opt/NinjaRMMAgent" ];
        Path = [
          pkgs.gzip
          pkgs.gnutar
        ];
      };
      environment = {
        DAEMON_RUN = "1";
        LC_ALL = "C";
      };
    };
  };
}
