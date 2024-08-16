{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    catppuccin.url = "github:catppuccin/nix";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty = {
      url = "git+ssh://git@github.com/ghostty-org/ghostty";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs";
    };
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
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
    ghostty,
    hyprland,
    ssh-keys,
    knixpkgs,
    lanzaboote,
    catppuccin,
    ...
  } @ inputs: rec {
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    defaultPackage."x86_64-linux" = home-manager.defaultPackage."x86_64-linux";
    homeConfigurations = {
      kar = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {system = "x86_64-linux";};
        specialArgs = {
          inherit inputs;
          home-manager = home-manager;
          catppuccin = catppuccin;
        };
        modules = [./belaf/home.nix];
      };
    };

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#'
    nixosConfigurations = {
      belaf = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          home-manager = home-manager;
          ghostty = ghostty;
          hyprland = hyprland;
          knixpkgs = knixpkgs;
          catppuccin = catppuccin;
          lanzaboote = lanzaboote;
        };

        modules = [
          ./belaf
        ];
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
    extra-substituters = ["https://hyprland.cachix.org" "https://ghostty.cachix.org"];
    extra-trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="];
    extra-experimental-features = ["nix-command" "flakes"];
  };
}
