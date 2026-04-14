{ config, lib, ... }:
let
  inherit (lib)
    mkMerge
    mkDefault
    ;
in
{
  imports = [
    ../../modules/services/acme-nginx.nix
  ];

  sops = {
    secrets.pds = {
      format = "dotenv";
      sopsFile = ../../secrets/pds.env;
      restartUnits = [ "bluesky-pds.service" ];
      owner = "pds";
      group = "pds";
    };
    secrets.cloudflare-api = {
      format = "dotenv";
      sopsFile = ../../secrets/cloudflare-api.env;
    };
  };

  services.bluesky-pds = {
    enable = mkDefault true;
    environmentFiles = [ config.sops.secrets.pds.path ];
    settings = mkMerge [
      {
        PDS_SQLITE_DISABLE_WAL_AUTO_CHECKPOINT = "true";
        PDS_DATA_DIRECTORY = "/var/lib/pds";
        PDS_HOSTNAME = "0xf.fr";
        PDS_BLOBSTORE_DISK_LOCATION = null;
      }
    ];
  };

  services.acme-nginx = {
    enable = true;
    email = "netop@0xf.fr";
    credentialsFile = config.sops.secrets.cloudflare-api.path;
    hosts = [
      {
        domain = "0xf.fr";
        extraDomainNames = [ "*.0xf.fr" ];
        proxyPort = config.services.bluesky-pds.settings.PDS_PORT;
      }
    ];
  };
}
