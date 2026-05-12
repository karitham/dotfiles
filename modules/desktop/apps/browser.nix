{
  lib,
  osConfig,
  pkgs,
  inputs',
  ...
}:
{
  config = lib.mkIf osConfig.desktop.apps.enable {
    home = {
      packages = [
        pkgs.firefox-devedition
        inputs'.helium.packages.default
      ];
    };
  };
}
