{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.catppuccin.nixosModules.catppuccin
    ../../modules/home
    ./hardware.nix
  ];
  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };
  time.timeZone = "Europe/Paris";
  desktop.enable = true;
  system.stateVersion = "25.11";

  boot = {
    loader.systemd-boot = {
      enable = lib.mkForce false;

      configurationLimit = 10;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    supportedFilesystems = ["bcachefs"];
    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking.networkmanager.enable = true;

  services = {
    tailscale.enable = true;
    tailscale.useRoutingFeatures = "client";
    touchegg.enable = true;
    auto-cpufreq.enable = true;
    blueman.enable = true;
    udev.packages = [pkgs.via];
  };

  hardware.keyboard.qmk.enable = true;

  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  environment = with pkgs; {
    systemPackages = [
      sbctl
    ];
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      data-root = "/docker";
    };
  };
}
