{
  pkgs,
  lib,
  inputs,
  ...
}: {
  nix.registry = {
    k.flake = inputs.knixpkgs;
  };
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
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.kar = {
      shell.name = "nu";
      shell.pkg = pkgs.nushell;
      catppuccin.enable = true;
      catppuccin.flavor = "macchiato";
      imports = [
        ../common/desktop/home
        (import ./desktop.nix {inherit inputs;})
        inputs.catppuccin.homeManagerModules.catppuccin
      ];
    };
  };

  imports = [
    ../common/fonts.nix
    ../common/shell.nix
    ../common/nixos/ipcam.nix
    ../common/desktop/desktop.nix
    ../common/desktop/greetd.nix

    inputs.lanzaboote.nixosModules.lanzaboote
    ./hardware.nix
    ./configuration.nix
    inputs.catppuccin.nixosModules.catppuccin
    inputs.home-manager.nixosModules.home-manager
  ];
}
