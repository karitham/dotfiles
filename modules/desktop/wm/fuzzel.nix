{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.fuzzel = lib.mkIf config.desktop.launcher.enable {
    enable = true;
    settings.main = {
      terminal = "ghostty";
    };
  };

  programs.niri.settings.binds = lib.mkIf config.desktop.launcher.enable {
    "Mod+R".action.spawn = "${lib.getExe pkgs.fuzzel}";
  };
}
