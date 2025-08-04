{
  osConfig,
  lib,
  ...
}: {
  config = lib.mkIf osConfig.desktop.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        preload = ["${osConfig.desktop.wallpaper}"];
        wallpaper = [", ${osConfig.desktop.wallpaper}"];
      };
    };
  };
}
