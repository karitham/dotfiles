{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf (config.desktop.enable && !config.desktop.noctalia.enable) {
    services.swww = {
      enable = true;
    };

    programs.niri.settings.spawn-at-startup = [
      {
        command = [
          (lib.getExe' pkgs.swww "swww")
          "img"
          "${config.desktop.wallpaper.image}"
        ];
      }
    ];
  };
}
