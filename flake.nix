{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs?rev=f7b11968ea1d19496487f6afaac99c130a87c1ff";
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
    knixpkgs = {
      url = "https://flakehub.com/f/karitham/knixpkgs/0.1.*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ssh-keys = {
      url = "https://github.com/karitham.keys";
      flake = false;
    };
  };
  outputs = inputs @ {nixpkgs, ...}: let
    # Common modules used across all systems
    commonModules = [
      ./modules/shell.nix
      ./modules/fonts.nix
      ./modules/nixos/shell.nix
      ./modules/nixos/nix.nix
    ];

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
        user = "kar";
        hasHome = false;
      };
      faputa = {
        user = "nixos";
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
              inherit hostname;
              username = cfg.user;
            };
        };
        modules =
          [
            ./hosts/${hostname}
          ]
          ++ commonModules;
      };
  in rec {
    nixosConfigurations = nixpkgs.lib.mapAttrs mkSystem systems;
    homeConfigurations = nixpkgs.lib.mapAttrs' (hostname: cfg: {
      name = "${cfg.user}@${hostname}";
      value = {config = nixosConfigurations.${hostname}.config.home-manager.users.${cfg.user};};
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
