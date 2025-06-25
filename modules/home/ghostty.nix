{
  osConfig,
  lib,
  ...
}: {
  config = lib.mkIf osConfig.desktop.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        font-family = "Cascadia Mono NF";
        font-size = 13;

        window-decoration = true;
        gtk-titlebar = false;

        custom-shader = "${./ghostty-shader.glsl}";
      };
    };
  };
}
