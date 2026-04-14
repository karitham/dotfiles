{ inputs, ... }:
{
  imports = [
    inputs.helix-plugins.homeManagerModules.default
    ./helix.nix
  ];
}
