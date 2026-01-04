{ config, self, ... }:
{
  imports = [
    self.nixosModules.pds
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

  services.pds-with-backups = {
    enable = true;
    secretsFiles = [ config.sops.secrets.pds.path ];
    settings = {
      PDS_HOSTNAME = "0xf.fr";
      PDS_BLOBSTORE_DISK_LOCATION = null;
    };
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
