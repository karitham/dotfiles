{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    catppuccin.url = "github:catppuccin/nix";
    spicetify-nix = {
      url = "github:gerg-l/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ssh-keys = {
      url = "https://github.com/karitham.keys";
      flake = false;
    };
  };
  outputs = inputs @ {nixpkgs, ...}: let
    # Unified system configuration
    systems = {
      belaf = {
        user = "kar";
        hasHome = true;
      };
      kiwi = {
        user = "kar";
        hasHome = true;
      };
      reg = {
        user = "root";
        hasHome = false;
      };
      ozen = {
        user = "nixos";
        hasHome = true;
      };
    };

    # Helper function to create NixOS configurations
    mkSystem = hostname: cfg:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inputs =
            inputs
            // {
              username = cfg.user;
            };
        };
        modules =
          [
            (_: {networking.hostName = hostname;})
            ./modules/nixos
            ./hosts/${hostname}
          ]
          ++ nixpkgs.lib.optionals cfg.hasHome [
            inputs.home-manager.nixosModules.home-manager
            ./modules/home
          ];
      };
  in rec {
    nixosConfigurations = nixpkgs.lib.mapAttrs mkSystem systems;
    homeConfigurations = nixpkgs.lib.mapAttrs' (hostname: cfg: {
      name = "${cfg.user}@${hostname}";
      value = {
        config = nixosConfigurations.${hostname}.config.home-manager.users.${cfg.user};
      };
    }) (nixpkgs.lib.filterAttrs (_: cfg: cfg.hasHome) systems);
  };
  nixConfig = {
    warn-dirty = false;
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
