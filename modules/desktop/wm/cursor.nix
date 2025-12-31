{ lib, config, ... }:
{
  config = lib.mkIf config.desktop.wm.enable {
    catppuccin.cursors.enable = true;
    home.pointerCursor = {
      gtk.enable = true;
      size = 16;
    };
  };
}
