{
  pkgs,
  lib,
  inputs,
  ...
}: {
  catppuccin.enable = true;
  catppuccin.flavor = "macchiato";
  desktop.enable = true;
  time.timeZone = "Europe/Paris";
  yubikey.enable = true;

  system = {
    stateVersion = "24.11";
  };

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

    # touchpad
    touchegg.enable = true;

    #power
    auto-cpufreq.enable = true;

    # bluetooth
    blueman.enable = true;

    # udev
    udev.packages = [pkgs.via];
  };

  hardware.keyboard.qmk.enable = true;

  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  programs.ssh.startAgent = true;
  environment = with pkgs; {
    systemPackages = [
      sbctl
      age
      wireguard-tools
    ];
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      data-root = "/docker";
    };
  };

  home-manager.users.kar.imports = [./desktop.nix];
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.catppuccin.nixosModules.catppuccin
    ./hardware.nix
  ];
}
