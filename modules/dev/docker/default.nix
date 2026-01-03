{ lib, ... }:
{
  virtualisation.docker = {
    enable = lib.mkDefault true;
    enableOnBoot = false;
    daemon.settings = {
      shutdown-timeout = 2;
    };
  };
}
