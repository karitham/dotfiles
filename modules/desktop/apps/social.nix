{
  lib,
  config,
  pkgs,
  self',
  ...
}:
{
  config = lib.mkIf config.desktop.apps.enable {
    programs.vesktop = {
      enable = true;
      package = self'.packages.vesktop;
    };
    home.packages = [ pkgs.signal-desktop ];
  };
}
