{
  self,
  inputs,
  lib,
  ...
}:
let
  hosts = import ./hosts.nix;

  # Reproduce the easy-hosts host attrs from ./hosts.nix: only emit `arch`
  # for non-default architectures and `tags` when non-empty, matching the
  # previous literal definition.
  toEasyHost =
    h:
    {
      inherit (h) class;
    }
    // lib.optionalAttrs (h.arch != "x86_64") { inherit (h) arch; }
    // lib.optionalAttrs (h.tags != [ ]) { inherit (h) tags; };
in
{
  imports = [ inputs.easy-hosts.flakeModule ];

  config.easy-hosts = {
    shared = {
      modules = [
        ../modules/core.nix
        ../modules/ninjaone.nix
        (_: { environment.defaultPackages = [ ]; })
      ];

      specialArgs = { inherit inputs self; };
    };

    additionalClasses = {
      desktop = "nixos";
      server = "nixos";
      wsl = "nixos";
    };

    perClass = class: { modules = [ ../modules/${class}/default.nix ]; };

    perTag = tag: { modules = [ ../modules/tags/${tag}.nix ]; };

    hosts = builtins.mapAttrs (_: toEasyHost) hosts;
  };
}
