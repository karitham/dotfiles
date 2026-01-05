{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.desktop.wm.enable {
    services.swww = {
      enable = true;
    };

    programs.niri.settings.spawn-at-startup = [
      {
        command = [
          (lib.getExe' pkgs.swww "swww")
          "img"
          "${config.desktop.wallpaper}"
        ];
      }
    ];
  };
}
