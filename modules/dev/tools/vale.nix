{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.dev.enable {
    home.packages = [ pkgs.vale ];

    xdg.configFile."vale/.vale.ini".source = ./vale/.vale.ini;
    xdg.configFile."vale/styles".source = ./vale/styles;
  };
}
