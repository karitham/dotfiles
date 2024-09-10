{
  lib,
  hyprland,
  home-manager,
  pkgs,
  knixpkgs,
  catppuccin,
  lanzaboote,
  ghostty,
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
  ];
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  imports = [
    ../common/fonts.nix
    ../common/shell.nix

    lanzaboote.nixosModules.lanzaboote
    ./hardware.nix
    ./desktop.nix
    ./configuration.nix
    ./fabric.nix
    catppuccin.nixosModules.catppuccin
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = {
        ghostty = ghostty;
      };
      home-manager.users.kar = {
        shell.name = "nu";
        shell.pkg = pkgs.nushell;
        catppuccin.enable = true;
        catppuccin.flavor = "macchiato";
        imports = [./home catppuccin.homeManagerModules.catppuccin];
      };
    }
    hyprland.nixosModules.default
    {programs.hyprland.enable = true;}
    ./greetd.nix
  ];
}
