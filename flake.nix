{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    systems.url = "github:nix-systems/default";
    catppuccin = {
      url = "github:catppuccin/nix";
    };
    helix = {
      url = "github:helix-editor/helix";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri.url = "github:sodiboo/niri-flake?ref=main";
    starship-jj.url = "gitlab:lanastara_foss/starship-jj";
    ssh-keys = {
      url = "https://github.com/karitham.keys";
      flake = false;
    };

    zjstatus = {
      url = "github:dj95/zjstatus";
    };
    knixpkgs = {
      url = "github:karitham/knixpkgs";
      inputs.nixpkgs.follows = "nixpkgs"; # use the same mesa as local system
    };

    tree-sitter-nu = {
      url = "github:nushell/tree-sitter-nu";
      flake = false;
    };

    topiary-nushell = {
      url = "github:blindFS/topiary-nushell";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
            (_: {
              networking.hostName = hostname;
              nix.registry = {
                self.flake = self;
              };
            })
            ./modules/nixos
            ./hosts/${hostname}
          ]
          ++ nixpkgs.lib.optionals (hasHome cfg) [
            inputs.home-manager.nixosModules.home-manager
            inputs.niri.nixosModules.niri
            ./modules/home
          ];
      };

    forAllSystems = function:
      nixpkgs.lib.genAttrs (import inputs.systems) (system: function nixpkgs.legacyPackages.${system});
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

    packages = forAllSystems (pkgs: {
      pokego = pkgs.callPackage ./pkgs/pokego.nix {};
      http-nu = pkgs.callPackage ./pkgs/http-nu.nix {};
      topiary-nu = pkgs.callPackage ./pkgs/topiary-nu.nix {
        inherit (inputs) tree-sitter-nu topiary-nushell;
      };
    });

    overlays.default = import ./overlays;
  };
  nixConfig = {
    warn-dirty = false;
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [
      "https://helix.cachix.org"
      "https://niri.cachix.org"
      "https://karitham.cachix.org"
      "https://ghostty.cachix.org"
    ];
    extra-trusted-public-keys = [
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "karitham.cachix.org-1:Q0wdHZsCssuepIrtx83gHibE0LTDYLVNnvaV3Nms9U0="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
    ];
  };
}
