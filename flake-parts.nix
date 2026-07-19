{
  self,
  inputs,
  withSystem,
  lib,
  ...
}:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  imports = [ ./systems/default.nix ];

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
        golangci-lint-langserver = pkgs.callPackage ./pkgs/golangci-lint-langserver.nix { };
        gotools = pkgs.callPackage ./pkgs/gotools.nix { };

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
          oxfmt
        ];
      };
    };

  flake = {
    lib.sdImageFromSystem = system: system.config.system.build.sdImage;

    homeModules = {
      common = import ./modules/home/common.nix;
      dev = import ./modules/dev/home.nix;
      desktop = import ./modules/desktop/home.nix;
      work = import ./modules/tags/work-home.nix;
    };

    nixosModules = {
      dev = import ./modules/dev/nixos.nix;
      desktop = import ./modules/desktop/nixos.nix;
    };

    # Standalone home-manager configs, one per machine, for fast iteration
    # (`home-manager switch --flake .#<host>`) without a full nixos-rebuild.
    # Generated from ./systems/hosts.nix so they stay in lock-step with the
    # NixOS `home-manager.users` path: same homeModules, same per-host
    # systems/<host>/home.nix, same tag content.
    homeConfigurations =
      let
        hosts = import ./systems/hosts.nix;
        homeHosts = lib.filterAttrs (_: h: h.class == "desktop" || h.class == "wsl") hosts;

        # Tags that carry home-manager content (mirrors modules/tags/<tag>.nix).
        tagHomeModules = {
          work = self.homeModules.work;
        };

        mkHome =
          name: host:
          withSystem "${host.arch}-linux" (
            { self', inputs', ... }:
            let
              # Match the NixOS `nixpkgs.config` (modules/nix.nix) so unfree
              # packages resolve the same way under `useGlobalPkgs`.
              pkgs = import inputs.nixpkgs {
                system = "${host.arch}-linux";
                config = {
                  allowUnfree = true;
                  input-fonts.acceptLicense = true;
                };
              };
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit
                  inputs
                  inputs'
                  self
                  self'
                  ;
              };

              modules = [
                self.homeModules.common
                self.homeModules.dev
              ]
              ++ lib.optionals (host.class == "desktop") [
                self.homeModules.desktop
                inputs.niri.homeModules.niri
              ]
              ++ lib.concatMap (t: lib.optional (tagHomeModules ? ${t}) tagHomeModules.${t}) host.tags
              ++ [
                ./systems/${name}/home.nix
                { home.homeDirectory = "/home/kar"; }
              ];
            }
          );
      in
      lib.mapAttrs' (name: host: lib.nameValuePair "kar@${name}" (mkHome name host)) homeHosts;
  };
}
