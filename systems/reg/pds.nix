{ config, ... }:
{
  imports = [ ../../modules/nixos/services/acme-nginx.nix ];
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
  };

  services.bluesky-pds = {
    enable = true;
    settings = {
      PDS_HOSTNAME = "0xf.fr";
    };
    environmentFiles = [ config.sops.secrets.pds.path ];
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
