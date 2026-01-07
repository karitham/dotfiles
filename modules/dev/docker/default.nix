{ lib, config, ... }:
{
  config = lib.mkIf config.dev.docker.enable {
    virtualisation.docker = {
      enable = lib.mkDefault true;
      enableOnBoot = false;
      daemon.settings = {
        shutdown-timeout = 2;
      };
    };
  };
}
