{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    knixpkgs = {
      url = "github:karitham/knixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
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
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = {
    self,
    nixpkgs,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} (
      {withSystem, ...}: {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        perSystem = {pkgs, ...}: {
          packages = {
            pokego = pkgs.callPackage ./pkgs/pokego.nix {};
            http-nu = pkgs.callPackage ./pkgs/http-nu.nix {};
            topiary-nu = pkgs.callPackage ./pkgs/topiary-nu.nix {
              inherit (inputs) tree-sitter-nu topiary-nushell;
            };

            wakuna-image = self.lib.sdImageFromSystem self.nixosConfigurations.wakuna;
          };
          formatter = pkgs.alejandra;
        };

        flake = let
          inherit (nixpkgs) lib;
        in {
          lib = {
            sdImageFromSystem = system: system.config.system.build.sdImage;

            mkSystem' = system: hostname:
              withSystem system (
                {
                  inputs',
                  self',
                  ...
                }:
                  lib.nixosSystem {
                    specialArgs = {
                      inherit
                        inputs
                        inputs'
                        self
                        self'
                        ;
                    };
                    modules = [
                      {networking.hostName = hostname;}
                      ./modules/core.nix
                      ./modules/nixos
                      ./hosts/${hostname}
                    ];
                  }
              );

            mkSystem = system: hostname: {${hostname} = self.lib.mkSystem' system hostname;};
            mkSystems = system: hosts: lib.mergeAttrsList (map (self.lib.mkSystem system) hosts);
          };

          nixosConfigurations = inputs.nixpkgs.lib.concatMapAttrs self.lib.mkSystems {
            "x86_64-linux" = [
              "ozen"
              "kiwi"
              "reg"
              "belaf"
            ];
            "aarch64-linux" = ["wakuna"];
          };

          overlays.default = import ./overlays;
        };
      }
    );
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
