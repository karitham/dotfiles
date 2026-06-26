{ pkgs, config, ... }: {
  imports = [ ./hardware.nix ];
  system.stateVersion = "26.05";
  desktop.noctalia.enable = true;

  boot = {
    supportedFilesystems = [ "bcachefs" ];
    kernelPackages = pkgs.linuxPackages_latest;
  };

  virtualisation.docker.daemon.settings.data-root = "/docker";

  home-manager.users.${config.my.username}.imports = [ ./home.nix ];
}
