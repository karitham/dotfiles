{ lib, config, ... }: {
  config = lib.mkIf config.desktop.enable {
    catppuccin.cursors.enable = true;
    home.pointerCursor = {
      enable = true;
      gtk.enable = true;
      size = 16;
    };
  };
}
