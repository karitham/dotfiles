{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.desktop.locale.enable (import ../locale.nix { inherit pkgs; });
}
