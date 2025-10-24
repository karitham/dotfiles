{
  config,
  pkgs,
  ...
}: let
  restoreScript = pkgs.writeShellScriptBin "pds-restore" ''
    set -e

    echo "Starting PDS restore..."

    set -a
    source ${config.sops.secrets.s3.path}
    set +a

    LATEST=$(${pkgs.awscli2}/bin/aws s3 ls s3://$S3_BUCKET/backups/ | sort | tail -1 | awk '{print $4}')
    [ -z "$LATEST" ] && echo "No backups found." && exit 1

    echo "Latest backup: $LATEST"
    ${pkgs.awscli2}/bin/aws s3 cp s3://$S3_BUCKET/backups/$LATEST /tmp/$LATEST

    systemctl stop bluesky-pds
    rm -rf /var/lib/pds/*

    ${pkgs.gnutar}/bin/tar -xzf /tmp/$LATEST -C /var/lib/pds
    chown -R pds:pds /var/lib/pds

    systemctl start bluesky-pds

    echo "Restore completed."
  '';
  backupScript = pkgs.writeShellScript "pds-backup-script" ''
    SOURCE_DIR="$PDS_DATA_DIR"
    S3_BUCKET="$S3_BUCKET"
    LOG_DIR="/var/log/pds-backup"
    DATE_LABEL=$(date +"%Y%m%d-%H%M")
    LOG_FILE="$LOG_DIR/$DATE_LABEL.log"
    ARCHIVE_FILE="/tmp/pds-backup-$DATE_LABEL.tar.gz"
    MAX_RETRIES=3
    RETRY_INTERVAL=60

    fail() {
        echo "$(date): ERROR: $1" | tee -a "$LOG_FILE"
        systemctl restart "$PDS_SERVICE" 2>/dev/null || echo "$(date): WARNING: Failed to restart PDS service after failure." >> "$LOG_FILE"
        exit 1
    }

    mkdir -p "$LOG_DIR"

    systemctl list-units --full -all | grep -Fq "$PDS_SERVICE.service" || fail "PDS service not found."

    systemctl stop "$PDS_SERVICE" 2>/dev/null && echo "$(date): Stopped PDS service." >> "$LOG_FILE" || echo "$(date): Failed to stop PDS service." >> "$LOG_FILE"

    [ -d "$SOURCE_DIR" ] || fail "Source directory $SOURCE_DIR does not exist."
    "$TAR_CMD" -czf "$ARCHIVE_FILE" -C "$SOURCE_DIR" . 2>> "$LOG_FILE" || fail "Failed to create archive."

    attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        if "$AWS_CMD" s3 cp "$ARCHIVE_FILE" "s3://$S3_BUCKET/backups/$DATE_LABEL.tar.gz" 2>> "$LOG_FILE"; then
            echo "$(date): Upload successful." >> "$LOG_FILE"
            break
        else
            [ $attempt -lt $MAX_RETRIES ] && sleep $RETRY_INTERVAL || fail "Upload failed after retries."
        fi
        ((attempt++))
    done

    rm -f "$ARCHIVE_FILE"

    systemctl start "$PDS_SERVICE" 2>/dev/null || fail "Failed to start PDS service."

    find "$LOG_DIR" -name "*.log" -mtime +90 -delete
    [ $(find "$LOG_FILE" -mtime +30) ] && mv "$LOG_FILE" "$LOG_FILE.old" && touch "$LOG_FILE"
    [ $(wc -l < "$LOG_FILE") -gt 1000 ] && mv "$LOG_FILE" "$LOG_FILE.old" && touch "$LOG_FILE"

    echo "$(date): Backup completed." >> "$LOG_FILE"
  '';
in {
  sops.secrets.s3 = {
    format = "dotenv";
    sopsFile = ../../secrets/pds-backup-s3.env;
  };

  environment.systemPackages = [restoreScript];

  systemd.services.pds-backup = {
    description = "Backup PDS data to S3";
    path = [pkgs.awscli2 pkgs.coreutils pkgs.gnutar pkgs.gzip];
    serviceConfig = {
      ExecStart = "${backupScript}";
      Environment = [
        "PDS_DATA_DIR=${config.services.bluesky-pds.settings.PDS_DATA_DIRECTORY}"
        "PDS_SERVICE=bluesky-pds"
        "TAR_CMD=${pkgs.gnutar}/bin/tar"
        "AWS_CMD=${pkgs.awscli2}/bin/aws"
      ];
      EnvironmentFile = [config.sops.secrets.s3.path];
      User = "root";
      Type = "oneshot";
    };
  };

  systemd.timers.pds-backup = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
