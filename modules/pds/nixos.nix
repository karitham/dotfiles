{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    mkMerge
    mkEnableOption
    mkDefault
    types
    ;

  cfg = config.services.pds-with-backups;

  pdsUser = "pds";
  pdsGroup = "pds";

  inherit (cfg) secretsFiles;

  litestreamConfig = pkgs.writeText "litestream-pds-config.yml" ''
    dbs:
      - dir: ${cfg.dataDir}
        pattern: "*.sqlite"
        recursive: true
        watch: true
        replica:
          type: s3
          path: ${cfg.backupS3Prefix}
          bucket: ''${S3_BUCKET}
  '';

  restoreScript = pkgs.writeShellApplication {
    name = "pds-litestream-restore";
    runtimeInputs = with pkgs; [
      awscli2
      litestream
      gnugrep
      gnused
      coreutils
      findutils
      gawk
    ];
    excludeShellChecks = [
      "SC1091"
      "SC2046"
      "SC2168"
      "SC1090"
      "SC2043"
    ];
    text = ''
      main() {
        set -euo pipefail

        echo "[PDS Restore] Starting automatic restore from S3..."

        for f in ${toString secretsFiles}; do
          if [ -f "$f" ]; then
            set -a
            source "$f"
            set +a
          else
            echo "[PDS Restore] Error: Secrets file not found: $f"
            exit 1
          fi
        done

        if [ -z "''${S3_BUCKET:-}" ]; then
          echo "[PDS Restore] Error: S3_BUCKET not set in secrets file"
          exit 1
        fi

        s3Bucket="''${S3_BUCKET}"
        s3Prefix="${cfg.backupS3Prefix}"

        run_aws() {
          local envArgs=()
          if [ -n "''${AWS_ENDPOINT_URL:-}" ]; then
            envArgs+=("AWS_ENDPOINT_URL=''${AWS_ENDPOINT_URL}")
          fi
          env "''${envArgs[@]}" aws "$@"
        }

        run_litestream() {
          local envArgs=()
          if [ -n "''${AWS_ENDPOINT_URL:-}" ]; then
            envArgs+=("AWS_ENDPOINT_URL=''${AWS_ENDPOINT_URL}")
          fi
          env "''${envArgs[@]}" litestream "$@"
        }

        echo "[PDS Restore] Verifying S3 connectivity..."
        local retries=5
        local connected=false
        for i in $(seq 1 $retries); do
          if run_aws s3 ls "s3://$s3Bucket/" &>/dev/null; then
            connected=true
            break
          fi
          echo "[PDS Restore] Waiting for S3 bucket (attempt $i/$retries)..."
          sleep 2
        done

        if [ "$connected" = false ]; then
          echo "[PDS Restore] Error: Cannot connect to S3 bucket: $s3Bucket"
          exit 1
        fi

        echo "[PDS Restore] S3 connection verified"

        local objects
        objects=$(run_aws s3 ls "s3://$s3Bucket/$s3Prefix" --recursive 2>/dev/null | awk '{print $4}' || true)

        local databases
        databases=$(echo "$objects" | grep '\.sqlite/' | sed 's|.*/\([^/]*\.sqlite\).*|\1|' | sort -u || true)

        if [ -z "$databases" ]; then
          echo "[PDS Restore] No databases found in S3 at s3://$s3Bucket/$s3Prefix"
          echo "[PDS Restore] New deployment - skipping restore."
          exit 0
        fi

        echo "[PDS Restore] Found databases to restore:"
        echo "$databases"
        echo ""

        mkdir -p "${cfg.dataDir}"

        local restoredCount=0
        for db in $databases; do
          local localPath="${cfg.dataDir}/$db"
          local s3DbPath="$s3Prefix/$db"
          local s3DbUrl="s3://$s3Bucket/$s3DbPath"

          if [ -f "$localPath" ]; then
            echo "[PDS Restore] Database already exists locally: $db (skipping)"
            continue
          fi

          echo "[PDS Restore] Restoring database: $db"
          mkdir -p "$(dirname "$localPath")"

          if run_litestream restore -if-db-not-exists -if-replica-exists -o "$localPath" "$s3DbUrl"; then
            echo "[PDS Restore] Successfully restored: $db"
            restoredCount=$((restoredCount + 1))

            if [ -f "$localPath" ]; then
              chown ${pdsUser}:${pdsGroup} "$localPath"
              chmod 644 "$localPath"
            fi
          else
            echo "[PDS Restore] Warning: Failed to restore $db"
          fi
        done

        echo ""
        echo "[PDS Restore] Restore completed. Restored $restoredCount database(s)."

        if [ $restoredCount -eq 0 ]; then
          echo "[PDS Restore] No new databases restored. PDS will start with fresh state."
        fi
      }

      main
    '';
  };

  healthCheckScript = pkgs.writeShellScript "pds-healthcheck" ''
    set -euo pipefail

    if ! systemctl is-active --quiet bluesky-pds; then
      echo "[PDS HealthCheck] PDS service is not running"
      exit 1
    fi

    if [ -f "${cfg.dataDir}/primary.sqlite" ]; then
      if ! systemctl is-active --quiet litestream-pds; then
        echo "[PDS HealthCheck] Litestream service is not running"
        exit 1
      fi
    fi

    echo "[PDS HealthCheck] All services healthy"
    exit 0
  '';
in
{
  options.services.pds-with-backups = {
    enable = mkEnableOption "Zero-Touch Recovery PDS with Litestream and S3 blob storage";

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/pds";
      description = "PDS data directory for SQLite databases.";
    };

    secretsFiles = mkOption {
      type = types.listOf types.path;
      description = ''
        List of paths to secrets files in dotenv format.
        All files will be sourced to load credentials.
        Required variables: PDS_JWT_SECRET, PDS_ADMIN_PASSWORD, PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX,
        AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, S3_BUCKET.
        Optional: AWS_ENDPOINT_URL.
      '';
      example = [ "/run/secrets/pds.env" ];
    };

    backupS3Prefix = mkOption {
      type = types.strMatching "[^/].*[^/]";
      default = "backups";
      description = "S3 directory prefix for Litestream replicas.";
      example = "pds-backups";
    };

    backupLogDir = mkOption {
      type = types.path;
      default = "/var/log/pds-backup";
      description = "Directory for backup and restore logs.";
      internal = true;
    };

    settings = mkOption {
      inherit (options.services.bluesky-pds.settings) type;
      default = { };
      description = "Additional settings to pass to bluesky-pds:\n\n" ++ options.services.bluesky-pds.settings.description;
      example = {
        PDS_PORT = 3000;
        PDS_HOSTNAME = "hi.example.com";
      };
    };
  };

  config = mkIf cfg.enable {
    services.bluesky-pds = {
      enable = mkDefault true;
      settings = mkMerge [
        {
          PDS_SQLITE_DISABLE_WAL_AUTO_CHECKPOINT = "true";
          PDS_DATA_DIRECTORY = cfg.dataDir;
        }
        cfg.settings
      ];
      environmentFiles = secretsFiles;
    };

    users.users.${pdsUser} = {
      isSystemUser = true;
      group = pdsGroup;
      description = "Bluesky PDS service user";
    };
    users.groups.${pdsGroup} = { };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 ${pdsUser} ${pdsGroup} -"
      "d ${cfg.backupLogDir} 0755 ${pdsUser} ${pdsGroup} -"
    ];

    systemd.services.bluesky-pds = {
      after = [
        "network.target"
        "pds-restore.service"
      ];
      wants = [ "pds-restore.service" ];
      serviceConfig.Restart = lib.mkDefault "on-failure";
      serviceConfig.RestartSec = "10s";
    };

    systemd.services.pds-restore = {
      description = "PDS Automatic Restore from S3";
      wantedBy = [ "multi-user.target" ];
      before = [ "bluesky-pds.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${restoreScript}/bin/pds-litestream-restore";
        EnvironmentFile = secretsFiles;
        User = pdsUser;
        Group = pdsGroup;
        RemainAfterExit = true;

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        RestrictRealtime = true;
      };
    };

    systemd.services.litestream-pds = {
      description = "Litestream real-time replication for PDS databases";
      after = [
        "network.target"
        "pds-restore.service"
        "bluesky-pds.service"
      ];
      requires = [ "bluesky-pds.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.litestream}/bin/litestream replicate -config ${litestreamConfig}";
        EnvironmentFile = secretsFiles;
        User = pdsUser;
        Group = pdsGroup;
        Restart = "on-failure";
        RestartSec = "5s";

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [
          cfg.dataDir
          cfg.backupLogDir
        ];
        RestrictRealtime = true;
        MemoryDenyWriteExecute = true;
      };
    };

    systemd.services.pds-healthcheck = {
      description = "PDS Health Check";
      after = [
        "bluesky-pds.service"
        "litestream-pds.service"
      ];
      requires = [ "bluesky-pds.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = healthCheckScript;
        User = pdsUser;
        Group = pdsGroup;

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };

      startAt = "hourly";
    };

    systemd.timers.pds-healthcheck = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };

    environment.systemPackages = with pkgs; [
      litestream
      restoreScript
      awscli2
    ];
  };
}
