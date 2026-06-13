{ config, lib, ... }:
let
  inherit (lib) mkMerge mkDefault;

  hosts = [
    {
      domain = "0xf.fr";
      extraDomainNames = [ "*.0xf.fr" ];
      proxyPort = config.services.bluesky-pds.settings.PDS_PORT;
    }
  ];
in
{
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

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  security.acme = {
    defaults.email = "netop@0xf.fr";
    acceptTerms = true;
    certs = lib.listToAttrs (
      map (host: {
        name = host.domain;
        value = {
          dnsProvider = "cloudflare";
          credentialFiles = {
            CLOUDFLARE_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare-api.path;
          };
          inherit (config.services.nginx) group;
          inherit (host) domain;
          extraDomainNames = host.extraDomainNames;
          reloadServices = [ "nginx" ];
        };
      }) hosts
    );
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = lib.listToAttrs (
      map (host: {
        name = "~(.*)\\.${lib.escapeRegex host.domain}$";
        value = {
          useACMEHost = host.domain;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString host.proxyPort}";
            proxyWebsockets = true;
          };
        };
      }) hosts
    );
  };
}
