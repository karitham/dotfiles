{ lib, config, ... }: {
  config = lib.mkIf config.desktop.wm.enable {
    catppuccin.cursors.enable = true;
    home.pointerCursor = {
      enable = true;
      gtk.enable = true;
      size = 16;
    };
  };
}
