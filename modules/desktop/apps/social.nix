{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf osConfig.desktop.apps.enable {
    programs.vesktop.enable = true;
    home.packages = [ pkgs.signal-desktop ];
  };
}
