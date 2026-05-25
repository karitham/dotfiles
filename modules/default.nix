{ self, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  imports = [ ../systems/default.nix ];

  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages = {
        pokego = pkgs.callPackage ./pkgs/pokego.nix { };
        http-nu = pkgs.callPackage ./pkgs/http-nu.nix { };
        malachite = pkgs.callPackage ./pkgs/malachite.nix { };
        litestream = pkgs.callPackage ./pkgs/litestream.nix { };
        multi-scrobbler = pkgs.callPackage ./pkgs/multi-scrobbler.nix { };
        golangci-lint-langserver = pkgs.callPackage ./pkgs/golangci-lint-langserver.nix { };
        gotools = pkgs.callPackage ./pkgs/gotools.nix { };
        skepsis = pkgs.callPackage ./pkgs/skepsis.nix { };

        wakuna-image = self.lib.sdImageFromSystem self.nixosConfigurations.wakuna;

        strands-agents-sops = pkgs.callPackage ./pkgs/strands-agents-sops.nix { };

        strands-sops-skills = pkgs.runCommand "strands-sops-skills" { } ''
          mkdir $out
          ${lib.getExe self'.packages.strands-agents-sops} skills --output-dir $out
        '';
      };
      formatter = pkgs.treefmt;
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          sops
          treefmt
          nixfmt
          nufmt
          biome
        ];
      };
    };

  flake = {
    lib.sdImageFromSystem = system: system.config.system.build.sdImage;

    homeModules = {
      dev = import ./dev/home.nix;
      desktop = import ./desktop/home.nix;
    };

    nixosModules = {
      dev = import ./dev/nixos.nix;
      desktop = import ./desktop/nixos.nix;
      acme-nginx = import ./services/acme-nginx.nix;
      multi-scrobbler = import ./services/multi-scrobbler.nix;
    };
  };
}
