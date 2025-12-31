{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.desktop.apps.enable {
    home = {
      packages = [ pkgs.firefox-devedition ];
    };
  };
}
