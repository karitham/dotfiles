{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.pds-backup;

  pdsUser = config.systemd.services.bluesky-pds.serviceConfig.User or "pds";
  pdsGroup = config.systemd.services.bluesky-pds.serviceConfig.Group or "pds";

  restoreScript = pkgs.writeShellApplication {
    name = "pds-restore";
    runtimeInputs = with pkgs; [
      awscli2
      gnutar
      coreutils
    ];
    excludeShellChecks = [ "SC1091" ];
    text = ''
      echo "Starting PDS restore..."

      if [ -f "${cfg.s3CredentialsFile}" ]; then
        set -a; source "${cfg.s3CredentialsFile}"; set +a
      else
        echo "Error: Credentials file not found at ${cfg.s3CredentialsFile}"
        exit 1
      fi

      backups=$(aws s3 ls "s3://$S3_BUCKET/backups/")
      if [ -z "$backups" ]; then
        echo "Error: No backups found in S3"
        exit 1
      fi

      LATEST=$(echo "$backups" | sort | tail -1 | awk '{print $4}')
      echo "Latest backup: $LATEST"

      local_file="/tmp/$LATEST"
      echo "Downloading backup..."
      if ! aws s3 cp "s3://$S3_BUCKET/backups/$LATEST" "$local_file"; then
        echo "Error: Failed to download backup"
        exit 1
      fi

      echo "Stopping PDS service..."
      systemctl stop bluesky-pds

      echo "Clearing existing data..."
      rm -rf ${cfg.pdsDataDir}/*

      echo "Extracting backup..."
      tar -xzf "$local_file" -C ${cfg.pdsDataDir}
      rm -f "$local_file"

      echo "Setting ownership..."
      chown -R ${pdsUser}:${pdsGroup} ${cfg.pdsDataDir}

      echo "Starting PDS service..."
      systemctl start bluesky-pds

      echo "Restore completed successfully."
    '';
  };

  backupScript = pkgs.writeShellApplication {
    name = "pds-backup-script";
    runtimeInputs = with pkgs; [
      awscli2
      gnutar
      gzip
      coreutils
    ];
    bashOptions = [ "errexit" ];
    text = ''
      log() {
        echo "$(date): $1" | tee -a "$LOG_FILE"
      }

      fail() {
        log "ERROR: $1"
        systemctl restart bluesky-pds 2>/dev/null || log "WARNING: Failed to restart PDS service"
        exit 1
      }

      cleanup_old_logs() {
        find "$LOG_DIR" -name "*.log" -mtime +90 -delete
        if [ "$(find "$LOG_FILE" -mtime +30 2>/dev/null)" ]; then
          mv "$LOG_FILE" "$LOG_FILE.old" && touch "$LOG_FILE"
        fi
        if [ "$(wc -l < "$LOG_FILE" 2>/dev/null)" -gt 1000 ]; then
          mv "$LOG_FILE" "$LOG_FILE.old" && touch "$LOG_FILE"
        fi
      }

      mkdir -p "$LOG_DIR"
      DATE_LABEL=$(date +"%Y%m%d-%H%M")
      LOG_FILE="$LOG_DIR/$DATE_LABEL.log"
      ARCHIVE_FILE="/tmp/pds-backup-$DATE_LABEL.tar.gz"
      ARCHIVE_NAME="$DATE_LABEL.tar.gz"

      log "Starting backup..."

      if ! systemctl list-units --full -all | grep -Fq "bluesky-pds.service"; then
        fail "PDS service not found"
      fi

      log "Stopping PDS service..."
      if ! systemctl stop bluesky-pds 2>/dev/null; then
        log "Failed to stop PDS service"
      fi

      if [ ! -d "$PDS_DATA_DIR" ]; then
        fail "Source directory $PDS_DATA_DIR does not exist"
      fi

      log "Creating archive..."
      if ! tar -czf "$ARCHIVE_FILE" -C "$PDS_DATA_DIR" . 2>> "$LOG_FILE"; then
        fail "Failed to create archive"
      fi

      log "Uploading to S3..."
      attempt=1
      while [ "$attempt" -le "$MAX_RETRIES" ]; do
        if aws s3 cp "$ARCHIVE_FILE" "s3://$S3_BUCKET/backups/$ARCHIVE_NAME" 2>> "$LOG_FILE"; then
          log "Upload successful"
          break
        else
          if [ "$attempt" -lt "$MAX_RETRIES" ]; then
            log "Upload failed, retrying in $RETRY_INTERVAL seconds..."
            sleep "$RETRY_INTERVAL"
          else
            fail "Upload failed after $MAX_RETRIES attempts"
          fi
        fi
        ((attempt++))
      done

      rm -f "$ARCHIVE_FILE"

      log "Starting PDS service..."
      if ! systemctl start bluesky-pds 2>/dev/null; then
        fail "Failed to start PDS service"
      fi

      log "Cleaning up old logs..."
      cleanup_old_logs

      log "Backup completed successfully"
    '';
  };

  litestreamConfigFile = pkgs.writeText "litestream-pds-config.yml" ''
    dbs:
      - dir: ${cfg.pdsDataDir}
        pattern: "*.sqlite"
        recursive: true
        watch: true
        replica:
          type: s3
          path: ${cfg.s3Prefix}
          endpoint: ''${AWS_ENDPOINT_URL}
          bucket: ''${S3_BUCKET}
          access-key-id: ''${AWS_ACCESS_KEY_ID}
          secret-access-key: ''${AWS_SECRET_ACCESS_KEY}
  '';

  litestreamRestore = pkgs.writeShellApplication {
    name = "pds-litestream-restore";
    runtimeInputs = with pkgs; [
      awscli2
      litestream
      gnugrep
      coreutils
    ];
    excludeShellChecks = [ "SC1091" ];
    text = ''
      set -e

      if [ -f "${cfg.s3CredentialsFile}" ]; then
        set -a; source "${cfg.s3CredentialsFile}"; set +a
      else
        echo "Error: Credentials file not found at ${cfg.s3CredentialsFile}"
        exit 1
      fi

      systemctl stop bluesky-pds

      S3_PREFIX="${cfg.s3Prefix}/"
      S3_URI="s3://$S3_BUCKET/$S3_PREFIX"
      MAP=$(aws s3 ls "$S3_URI" --recursive --endpoint-url "$AWS_ENDPOINT_URL" | grep -oE "$S3_PREFIX.+\.sqlite/" | sort -u)

      if [ -z "$MAP" ]; then
          echo "No databases found in S3."
          exit 2
      fi

      for S3_DB_PATH in $MAP; do
          REL_PATH=''${S3_DB_PATH#"$S3_PREFIX"}
          REL_PATH=''${REL_PATH%/}
          S3_DB_REPLICA_URL="s3://$S3_BUCKET/$S3_DB_PATH?endpoint=$AWS_ENDPOINT_URL"
          S3_DB_REPLICA_URL=''${S3_DB_REPLICA_URL%/}

          litestream restore -if-db-not-exists -if-replica-exists -o "${cfg.pdsDataDir}/$REL_PATH" "$S3_DB_REPLICA_URL"

          chown ${pdsUser}:${pdsGroup} "${cfg.pdsDataDir}/$REL_PATH"
      done

      systemctl start bluesky-pds
    '';
  };
in
{
  options.services.pds-backup = {
    enable = lib.mkEnableOption "PDS backup with Litestream and S3 archive";
    pdsDataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/pds";
      description = "PDS data directory.";
    };
    pdsSecretsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to PDS secrets file (dotenv format).";
    };
    s3Prefix = lib.mkOption {
      type = lib.types.strMatching "[^/].*[^/]";
      default = "pds";
      description = "S3 directory subpath.";
    };
    s3CredentialsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to S3 credentials file (containing AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, S3_BUCKET, etc).";
    };
    pdsSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional settings to pass to bluesky-pds.";
    };
    backupLogDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/log/pds-backup";
      description = "Directory for backup logs.";
    };
    maxRetries = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Maximum number of retry attempts for S3 upload.";
    };
    retryInterval = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "Seconds to wait between retry attempts.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.bluesky-pds = {
      enable = true;
      settings = lib.mkMerge [
        { PDS_SQLITE_DISABLE_WAL_AUTO_CHECKPOINT = "true"; }
        cfg.pdsSettings
      ];
      environmentFiles = [ cfg.pdsSecretsFile ];
    };

    systemd.services.litestream-pds = {
      description = "Litestream backup for PDS databases";
      after = [
        "network.target"
        "bluesky-pds.service"
      ];
      requires = [ "bluesky-pds.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.litestream}/bin/litestream replicate -config ${litestreamConfigFile}";
        EnvironmentFile = cfg.s3CredentialsFile;
        User = pdsUser;
        Group = pdsGroup;
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        ProtectSystem = "full";
        RestrictRealtime = true;
      };
    };

    systemd.services.pds-backup = {
      description = "Backup PDS data to S3";
      serviceConfig = {
        ExecStart = "${backupScript}/bin/pds-backup-script";
        Environment = [
          "PDS_DATA_DIR=${cfg.pdsDataDir}"
          "LOG_DIR=${cfg.backupLogDir}"
          "MAX_RETRIES=${toString cfg.maxRetries}"
          "RETRY_INTERVAL=${toString cfg.retryInterval}"
        ];
        EnvironmentFile = [ cfg.s3CredentialsFile ];
        User = "root";
        Type = "oneshot";
      };
    };

    systemd.timers.pds-backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    environment.systemPackages = [
      restoreScript
      litestreamRestore
      pkgs.litestream
    ];
  };
}
