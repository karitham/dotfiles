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
    ssh-keys = {
      url = "https://github.com/karitham.keys";
      flake = false;
    };
  };
  outputs = {
    nixpkgs,
    home-manager,
    ssh-keys,
    knixpkgs,
    lanzaboote,
    catppuccin,
    zen-browser,
    ...
  } @ inputs: rec {
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#'
    nixosConfigurations = {
      belaf = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          home-manager = home-manager;
          knixpkgs = knixpkgs;
          catppuccin = catppuccin;
          lanzaboote = lanzaboote;
          zen-browser = zen-browser;
        };

        modules = [./belaf];
      };

      kiwi = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          home-manager = home-manager;
          knixpkgs = knixpkgs;
          catppuccin = catppuccin;
          zen-browser = zen-browser;
        };

        modules = [./kiwi];
      };

      reg = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          ssh-keys = ssh-keys;
        };

        modules = [./reg];
      };

      faputa = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          ssh-keys = ssh-keys;
        };

        modules = [./faputa];
      };
    };

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
  nixConfig = {
    extra-experimental-features = ["nix-command" "flakes"];
  };
}
