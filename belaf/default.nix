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
        imports = [./home catppuccin.homeManagerModules.catppuccin];
        catppuccin.enable = true;
        catppuccin.flavor = "macchiato";
      };
    }
    hyprland.nixosModules.default
    {programs.hyprland.enable = true;}
    ./greetd.nix
  ];
}
