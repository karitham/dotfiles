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

  perSystem = { pkgs, lib, ... }: {
    packages = lib.packagesFromDirectoryRecursive {
      inherit (pkgs) callPackage;
      directory = ./pkgs;
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
                # HM's nix.conf generation requires an explicit package; the
                # NixOS path gets one from modules/nix.nix, this one doesn't.
                { nix.package = pkgs.nix; }
              ]
              ++ lib.optionals (host.class == "desktop") [
                self.homeModules.desktop
                inputs.niri.homeModules.niri
                # The niri HM module validates settings with
                # programs.niri.package, which otherwise defaults to
                # nixpkgs niri here and forces a source build. The NixOS
                # path overrides this in modules/desktop/desktop.nix.
                { programs.niri.package = inputs'.niri.packages.niri-unstable; }
              ]
              ++ lib.optionals (builtins.elem "work" host.tags) [ self.homeModules.work ]
              # Per-host home overrides are optional.
              ++ lib.optionals (builtins.pathExists ./systems/${name}/home.nix) [ ./systems/${name}/home.nix ];
            }
          );
      in
      lib.mapAttrs' (name: host: lib.nameValuePair "kar@${name}" (mkHome name host)) homeHosts;
  };
}
