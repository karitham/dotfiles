{config, ...}: {
  sops = {
    secrets.pds = {
      format = "dotenv";
      sopsFile = ../../secrets/pds.env;
      restartUnits = ["bluesky-pds.service"];
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
    environmentFiles = [config.sops.secrets.pds.path];
  };

  networking.firewall.allowedTCPPorts = [80 443];

  security.acme = {
    defaults.email = "netop@0xf.fr";
    acceptTerms = true;

    certs."0xf.fr" = {
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets.cloudflare-api.path;
      inherit (config.services.nginx) group;

      domain = "0xf.fr";
      extraDomainNames = ["*.0xf.fr"];
      reloadServices = ["nginx"];
    };
  };

  services.nginx = let
    pass = {
      useACMEHost = "0xf.fr";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString config.services.bluesky-pds.settings.PDS_PORT}";
        proxyWebsockets = true;
      };
    };
  in {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."~(.*)\\.0xf\\.fr$" = pass;
  };
}
