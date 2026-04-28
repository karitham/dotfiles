{
  inputs,
  config,
  osConfig,
  lib,
  ...
}:
let
  settings = lib.importJSON ./settings.json;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkIf osConfig.desktop.noctalia.enable {
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
      };
    };

    programs.noctalia-shell = {
      enable = true;
      inherit settings;
    };
  };
}
