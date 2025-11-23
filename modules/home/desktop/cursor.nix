{
  lib,
  osConfig,
  ...
}: {
  config = lib.mkIf osConfig.desktop.enable {
    catppuccin.cursors.enable = true;
    home.pointerCursor = {
      gtk.enable = true;
      size = 16;
    };
  };
}
