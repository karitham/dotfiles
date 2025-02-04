{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    catppuccin.url = "github:catppuccin/nix";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    knixpkgs.url = "https://flakehub.com/f/karitham/knixpkgs/0.1.*.tar.gz";
    knixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    spicetify-nix.url = "github:gerg-l/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";
    ssh-keys = {
      url = "https://github.com/karitham.keys";
      flake = false;
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: rec {
    nixosConfigurations = let
      system = "x86_64-linux";
    in {
      belaf = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs self;
        };

        modules = [./belaf];
      };

      kiwi = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs self;
        };

        modules = [./kiwi];
      };

      reg = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs self;
        };

        modules = [./reg];
      };

      faputa = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs self;
        };

        modules = [./faputa];
      };
    };

    homeConfigurations = {
      "kar@kiwi".config = nixosConfigurations.kiwi.config.home-manager.users.kar;
      "kar@belaf".config = nixosConfigurations.belaf.config.home-manager.users.kar;
    };
  };
  nixConfig = {
    extra-experimental-features = ["nix-command" "flakes"];
  };
}
