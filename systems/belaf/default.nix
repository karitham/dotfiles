{ pkgs, config, ... }: {
  imports = [ ./hardware.nix ];
  system.stateVersion = "26.05";
  desktop.noctalia.enable = true;

  boot = {
    supportedFilesystems = [ "bcachefs" ];
    kernelPackages = pkgs.linuxPackages_latest;
  };

  virtualisation.docker.daemon.settings.data-root = "/docker";

  home-manager.users.${config.my.username}.programs.niri.settings.outputs.eDP-1.mode = {
    width = 2560;
    height = 1600;
  };
}
