{
  pkgs,
  lib,
  inputs,
  ...
}: {
  catppuccin.enable = true;
  catppuccin.flavor = "macchiato";
  shell.name = "nu";
  shell.pkg = pkgs.nushell;

  system = {stateVersion = "24.05";};

  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
    inputs.zen-browser.packages."${pkgs.system}".default
  ];
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  programs.hyprland.enable = true;

  home-manager.users.kar.imports = [./desktop.nix];

  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.catppuccin.nixosModules.catppuccin
    inputs.home-manager.nixosModules.home-manager
    ../common/home

    ../common/fonts.nix
    ../common/shell.nix
    ../common/nixos/greetd.nix
    ../common/nixos/ipcam.nix
    ../common/nixos/nix.nix
    ./hardware.nix
    ./configuration.nix
  ];
}
