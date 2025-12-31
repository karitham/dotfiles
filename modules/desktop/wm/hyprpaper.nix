{ config, lib, ... }:
{
  config = lib.mkIf config.desktop.wm.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        preload = [ "${config.desktop.wallpaper}" ];
        wallpaper = [ ", ${config.desktop.wallpaper}" ];
      };
    };
  };
}
