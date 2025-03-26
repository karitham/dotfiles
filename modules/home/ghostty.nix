{
  osConfig,
  lib,
  ...
}: {
  config = lib.mkIf osConfig.desktop.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        font-family = osConfig.fonts.mono;
        font-size = 11;
        font-feature = ["-calt" "-liga" "-dlig"];

        window-decoration = true;
        gtk-titlebar = false;

        keybind = ["ctrl+alt+v=new_split:right"];
      };
    };
  };
}
