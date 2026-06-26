{ config, lib, ... }: {
  config = lib.mkIf config.desktop.terminal.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        font-family = config.fonts.mono;
        font-size = 12;
        window-decoration = true;
        gtk-titlebar = false;

        custom-shader-animation = "always";
        custom-shader = "${./ghostty-shader.glsl}";
      };
    };
  };
}
