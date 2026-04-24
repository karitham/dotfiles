{
  lib,
  config,
  pkgs,
  inputs',
  ...
}:
{
  config = lib.mkIf config.desktop.apps.enable {
    home = {
      packages = [
        pkgs.firefox-devedition
        inputs'.helium.packages.default
      ];
    };
  };
}
