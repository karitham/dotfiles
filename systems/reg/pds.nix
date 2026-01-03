{ config, self, ... }:
{
  imports = [
    self.nixosModules.pds-backup
    ../../modules/services/acme-nginx.nix
  ];

  sops = {
    secrets.pds = {
      format = "dotenv";
      sopsFile = ../../secrets/pds.env;
      restartUnits = [ "bluesky-pds.service" ];
    };
    secrets.cloudflare-api = {
      format = "dotenv";
      sopsFile = ../../secrets/cloudflare-api.env;
    };
    secrets.pds-s3 = {
      format = "dotenv";
      sopsFile = ../../secrets/pds-backup-s3.env;
    };
  };

  services.pds-backup = {
    enable = true;
    pdsSecretsFile = config.sops.secrets.pds.path;
    s3CredentialsFile = config.sops.secrets.pds-s3.path;

    pdsSettings = {
      PDS_HOSTNAME = "0xf.fr";
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
