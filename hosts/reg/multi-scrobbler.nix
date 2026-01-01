{ config, self, ... }:
{
  imports = [ self.nixosModules.multi-scrobbler ];

  sops.secrets."multi-scrobbler.json" = {
    # https://github.com/Mic92/sops-nix?tab=readme-ov-file#emit-plain-file-for-yaml-and-json-formats
    key = "";
    format = "json";
    sopsFile = ../../secrets/multi-scrobbler.json;
    owner = config.services.multi-scrobbler.group;
    group = config.services.multi-scrobbler.user;
    path = config.services.multi-scrobbler.configFile;
    restartUnits = [ "multi-scrobbler.service" ];
  };

  services.multi-scrobbler.enable = true;
}
