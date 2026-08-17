{ pkgs, config, ... }: {
  imports = [ ./hardware.nix ];
  system.stateVersion = "26.05";
  desktop.noctalia.enable = true;

  boot = {
    supportedFilesystems = [ "bcachefs" ];
    kernelPackages = pkgs.linuxPackages_latest;
  };

  virtualisation.docker.daemon.settings.data-root = "/docker";
  systemd.services.attic-push.enable = false;

  home-manager.users.${config.my.username}.imports = [ ./home.nix ];
}
