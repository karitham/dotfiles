{
  config,
  lib,
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
  inherit (cfg) secretsFiles;
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
  };
}
