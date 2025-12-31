{ config, lib, ... }:
let
  cfg = config.services.acme-nginx;
  hostType = lib.types.submodule {
    options = {
      domain = lib.mkOption {
        type = lib.types.str;
        description = "The main domain for this host.";
      };
      extraDomainNames = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra domain names for this host.";
      };
      proxyPort = lib.mkOption {
        type = lib.types.int;
        description = "The port to proxy to locally for this host.";
      };
    };
  };
in
{
  options.services.acme-nginx = {
    enable = lib.mkEnableOption "ACME and Nginx reverse proxy";

    email = lib.mkOption {
      type = lib.types.str;
      description = "Email for ACME.";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the credentials file for DNS provider.";
    };

    hosts = lib.mkOption {
      type = lib.types.listOf hostType;
      default = [ ];
      description = "List of hosts to configure.";
      example = [
        {
          domain = "example.com";
          extraDomainNames = [ "*.example.com" ];
          proxyPort = 3000;
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    security.acme = {
      defaults.email = cfg.email;
      acceptTerms = true;
      certs = lib.listToAttrs (
        map (host: {
          name = host.domain;
          value = {
            dnsProvider = "cloudflare";
            inherit (cfg) credentialsFile;
            inherit (config.services.nginx) group;
            inherit (host) domain;
            extraDomainNames = host.extraDomainNames or [ ];
            reloadServices = [ "nginx" ];
          };
        }) cfg.hosts
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
        }) cfg.hosts
      );
    };
  };
}
