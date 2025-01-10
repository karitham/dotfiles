{
  lib,
  home-manager,
  pkgs,
  knixpkgs,
  catppuccin,
  lanzaboote,
  zen-browser,
  ...
}: {
  nix.registry = {
    k.flake = knixpkgs;
  };
  catppuccin.enable = true;
  catppuccin.flavor = "macchiato";
  shell.name = "nu";
  shell.pkg = pkgs.nushell;

  system = {stateVersion = "24.05";};

  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
    zen-browser.packages."${pkgs.system}".default
  ];
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  programs.hyprland.enable = true;
  imports = [
    ../common/fonts.nix
    ../common/shell.nix
    ../common/nixos/ipcam.nix
    ../common/desktop/desktop.nix
    ../common/desktop/greetd.nix

    lanzaboote.nixosModules.lanzaboote
    ./hardware.nix
    ./configuration.nix
    catppuccin.nixosModules.catppuccin
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.kar = {
        shell.name = "nu";
        shell.pkg = pkgs.nushell;
        catppuccin.enable = true;
        catppuccin.flavor = "macchiato";
        imports = [../common/desktop/home catppuccin.homeManagerModules.catppuccin ./desktop.nix];
      };
    }
  ];
}
