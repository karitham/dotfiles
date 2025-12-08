{
  osConfig,
  lib,
  inputs',
  ...
}: {
  config = lib.mkIf osConfig.desktop.enable {
    programs.ghostty = {
      enable = true;
      package = inputs'.ghostty.packages.default;
      settings = {
        font-family = osConfig.fonts.mono;
        font-size = 13;
        window-decoration = true;
        gtk-titlebar = false;


        custom-shader-animation = "always";
        custom-shader = "${./ghostty-shader.glsl}";
      };
    };
  };
}
