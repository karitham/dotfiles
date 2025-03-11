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
    helix = {
      url = "github:helix-editor/helix";
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
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    hasHome = cfg: (cfg ? home) && cfg.home;

    # Unified system configuration
    systems = {
      belaf = {
        user = "kar";
        home = true;
        arch = "x86_64-linux";
      };
      kiwi = {
        user = "kar";
        home = true;
        arch = "x86_64-linux";
      };
      reg = {
        user = "root";
        arch = "x86_64-linux";
      };
      ozen = {
        user = "nixos";
        home = true;
        arch = "x86_64-linux";
      };
      wakuna = {
        user = "root";
        arch = "aarch64-linux";
      };
    };

    # Helper function to create NixOS configurations
    mkSystem = hostname: cfg:
      nixpkgs.lib.nixosSystem {
        specialArgs = let
          inherit (nixpkgs) lib;
        in {
          inherit inputs;
          username = cfg.user;
          inputs' = lib.mapAttrs (_: lib.mapAttrs (_: v: v.${cfg.arch} or v)) inputs;
        };
        modules =
          [
            (_: {networking.hostName = hostname;})
            ./modules/nixos
            ./hosts/${hostname}
          ]
          ++ nixpkgs.lib.optionals (hasHome cfg) [
            inputs.home-manager.nixosModules.home-manager
            ./modules/home
          ];
      };
  in {
    nixosConfigurations = nixpkgs.lib.mapAttrs mkSystem systems;

    homeConfigurations = nixpkgs.lib.mapAttrs' (hostname: cfg: {
      name = "${cfg.user}@${hostname}";
      value = {
        config = self.nixosConfigurations.${hostname}.config.home-manager.users.${cfg.user};
      };
    }) (nixpkgs.lib.filterAttrs (_: hasHome) systems);

    images = {
      wakuna = self.nixosConfigurations.wakuna.config.system.build.sdImage;
    };
  };

  nixConfig = {
    warn-dirty = false;
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
