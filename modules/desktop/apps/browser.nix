{
  lib,
  config,
  pkgs,
  inputs',
  ...
}:
{
  config = lib.mkIf config.desktop.enable {
    home = {
      packages = [
        pkgs.firefox
        inputs'.helium.packages.default
      ];
    };
  };
}
