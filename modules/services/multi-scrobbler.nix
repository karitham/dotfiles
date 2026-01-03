{
  config,
  lib,
  self',
  ...
}:
let
  cfg = config.services.multi-scrobbler;
in
{
  options.services.multi-scrobbler = {
    enable = lib.mkEnableOption "Multi-Scrobbler service";

    configFile = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/multi-scrobbler/config.json";
      description = "Path to the multi-scrobbler configuration file (AIO JSON format).";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall port for multi-scrobbler web UI.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9078;
      description = "Port for the multi-scrobbler web UI.";
    };

    resourceLimits = {
      memoryMax = lib.mkOption {
        type = lib.types.str;
        default = "1G";
        description = "Maximum memory for the systemd service.";
      };

      cpuQuota = lib.mkOption {
        type = lib.types.str;
        default = "50%";
        description = "CPU quota for the systemd service.";
      };
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "multi-scrobbler";
      description = "User account under which multi-scrobbler runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "multi-scrobbler";
      description = "Group account under which multi-scrobbler runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "Multi-Scrobbler service user";
    };

    users.groups.${cfg.group} = { };

    systemd.services.multi-scrobbler = {
      description = "Multi-Scrobbler - scrobble plays from multiple sources to multiple clients";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "multi-scrobbler";

        ExecStart = "${self'.packages.multi-scrobbler}/bin/multi-scrobbler";
        Environment = [
          "PORT=${toString cfg.port}"
          "CONFIG_DIR=/var/lib/multi-scrobbler"
          "NODE_ENV=production"
          "NODE_PATH=${self'.packages.multi-scrobbler}/share/multi-scrobbler/node_modules"
        ];

        Restart = "on-failure";
        RestartSec = "30s";

        MemoryMax = cfg.resourceLimits.memoryMax;
        CPUQuota = cfg.resourceLimits.cpuQuota;

        ReadOnlyPaths = [ "/nix/store" ];
        ReadWritePaths = [ "/var/lib/multi-scrobbler" ];

        ProtectSystem = "yes";
        ProtectHome = "yes";
        PrivateTmp = "yes";
        NoNewPrivileges = "yes";
        PrivateDevices = "yes";
      };
    };

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;
  };
}
