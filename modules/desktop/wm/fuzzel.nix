{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.desktop.launcher.enable {
    programs.fuzzel = {
      enable = true;
      settings.main = {
        terminal = "ghostty";
      };
    };

    programs.niri.settings.binds = {
      "Mod+R".action.spawn = "${lib.getExe pkgs.fuzzel}";
    };
  };
}
