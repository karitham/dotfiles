{
  inputs,
  config,
  lib,
  ...
}:
let
  settings = lib.importJSON ./settings.json;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkIf config.desktop.noctalia.enable {
    qt = {
      enable = true;
      style.name = "kvantum";
    };

    home.file.".cache/noctalia/wallpapers.json" = {
      text = builtins.toJSON { defaultWallpaper = config.desktop.wallpaper.image; };
    };

    programs.niri.settings = {
      spawn-at-startup = [ { command = [ (lib.getExe config.programs.noctalia-shell.package) ]; } ];

      binds = {
        "Mod+R".action.spawn = [
          "noctalia-shell"
          "ipc"
          "call"
          "launcher"
          "toggle"
        ];
        "Mod+Shift+N".action.spawn = [
          "noctalia-shell"
          "ipc"
          "call"
          "controlCenter"
          "toggle"
        ];
        "Mod+Shift+O".action.spawn = [
          "noctalia-shell"
          "ipc"
          "call"
          "sessionMenu"
          "toggle"
        ];
      };
    };

    programs.noctalia-shell = {
      enable = true;
      inherit settings;
    };
  };
}
