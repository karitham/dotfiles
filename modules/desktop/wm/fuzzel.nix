{
  osConfig,
  lib,
  pkgs,
  ...
}:
{
  programs.fuzzel = lib.mkIf osConfig.desktop.launcher.enable {
    enable = true;
    settings.main = {
      terminal = "ghostty";
    };
  };

  programs.niri.settings.binds = lib.mkIf osConfig.desktop.launcher.enable {
    "Mod+R".action.spawn = "${lib.getExe pkgs.fuzzel}";
  };
}
