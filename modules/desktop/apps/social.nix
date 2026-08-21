{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.desktop.enable {
    programs.vesktop.enable = true;
    home.packages = [ pkgs.signal-desktop ];
  };
}
