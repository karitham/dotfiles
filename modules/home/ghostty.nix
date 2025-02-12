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

        window-decoration = true;
        gtk-titlebar = false;

        background = "24273a";
        foreground = "cad3f5";
        selection-background = "363a4f";
        selection-foreground = "24273a";

        keybind = [
          "ctrl+alt+v=new_split:right"
        ];

        palette = [
          "0=#24273a"
          "1=#ed8796"
          "2=#a6da95"
          "3=#eed49f"
          "4=#8aadf4"
          "5=#c6a0f6"
          "6=#8bd5ca"
          "7=#cad3f5"
          "8=#494d64"
          "9=#ed8796"
          "10=#a6da95"
          "11=#eed49f"
          "12=#8aadf4"
          "13=#c6a0f6"
          "14=#8bd5ca"
          "15=#b7bdf8"
          "16=#f5a97f"
          "17=#f0c6c6"
          "18=#1e2030"
          "19=#363a4f"
          "20=#5b6078"
          "21=#f4dbd6"
        ];
      };
    };
  };
}
