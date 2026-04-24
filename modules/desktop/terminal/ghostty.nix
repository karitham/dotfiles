{
  config,
  osConfig,
  lib,
  ...
}:
{
  config = lib.mkIf osConfig.desktop.terminal.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        font-family = osConfig.fonts.mono;
        font-size = 12;
        window-decoration = true;
        gtk-titlebar = false;

        custom-shader-animation = "always";
        custom-shader = "${./ghostty-shader.glsl}";
      };
    };
  };
}
