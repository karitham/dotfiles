{
  withSystem,
  self,
  nixpkgs,
  inputs,
  ...
}:
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
        topiary-nu = pkgs.callPackage ./pkgs/topiary-nu.nix { };
        malachite = pkgs.callPackage ./pkgs/malachite.nix { };
        multi-scrobbler = pkgs.callPackage ./pkgs/multi-scrobbler.nix { };

        wakuna-image = self.lib.sdImageFromSystem self.nixosConfigurations.wakuna;

        strands-agents-sops = pkgs.callPackage ./pkgs/strands-agents-sops.nix { };

        strands-sops-skills = pkgs.runCommand "strands-sops-skills" { } ''
          mkdir $out
          ${lib.getExe self'.packages.strands-agents-sops} skills --output-dir $out
        '';

        strands-sops-commands = pkgs.runCommand "strands-sops-commands" { } ''
          mkdir $out
          ${lib.getExe self'.packages.strands-agents-sops} commands --type cursor --output-dir $out
          for f in $out/*.sop.md; do
            [ -f "$f" ] && mv "$f" "''${f%.sop.md}.md"
          done
        '';
      };
      checks = {
        pds-simple = pkgs.callPackage ./pds/pds-recovery-simple.nix { inherit (inputs) nixpkgs; };
        pds-full = pkgs.callPackage ./pds/pds-recovery-full.nix { inherit (inputs) nixpkgs; };
      };
      formatter = pkgs.nixfmt;
      devShells.default = pkgs.mkShell { packages = with pkgs; [ sops ]; };
    };

  flake =
    let
      inherit (nixpkgs) lib;
    in
    {
      lib = {
        sdImageFromSystem = system: system.config.system.build.sdImage;

        mkSystem' =
          system: hostname:
          withSystem system (
            { inputs', self', ... }:
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
                { networking.hostName = hostname; }
                ./core.nix
                ./systems/${hostname}
              ];
            }
          );

        mkSystem = system: hostname: { ${hostname} = self.lib.mkSystem' system hostname; };
        mkSystems = system: hosts: lib.mergeAttrsList (map (self.lib.mkSystem system) hosts);
      };

      overlays.default = import ./overlays;

      homeModules = {
        dev = import ./dev/home.nix;
        desktop = import ./desktop/home.nix;
      };

      nixosModules = {
        dev = import ./dev/nixos.nix;
        desktop = import ./desktop/nixos.nix;
        multi-scrobbler = import ./services/multi-scrobbler.nix;
        pds = import ./pds/nixos.nix;
      };
    };
}
