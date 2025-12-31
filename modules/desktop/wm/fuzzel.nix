{ config, lib, ... }:
{
  programs.fuzzel = lib.mkIf config.desktop.wm.enable {
    enable = true;
    settings.main = {
      terminal = "ghostty";
    };
  };
}
