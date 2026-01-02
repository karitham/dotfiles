{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];
  system.stateVersion = "25.11";

  boot = {
    supportedFilesystems = [ "bcachefs" ];
    kernelPackages = pkgs.linuxPackages_latest;
  };

  virtualisation.docker.daemon.settings = {
    data-root = "/docker";
  };
}
