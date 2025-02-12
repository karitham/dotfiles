{
  config,
  pkgs,
  osConfig,
  lib,
  ...
}: let
  inherit (config.lib.formats.rasi) mkLiteral;
in {
  config = lib.mkIf osConfig.desktop.enable {
    services.dunst.enable = true;

    programs.rofi.enable = true;
    programs.rofi.package = pkgs.rofi-wayland-unwrapped;
    programs.rofi.theme = {
      "*" = {
        bg-col = mkLiteral "#232634";
        bg-col-light = mkLiteral "#303446";
        border-col = mkLiteral "#303446";
        selected-col = mkLiteral "#303446";
        blue = mkLiteral "#7DC4E4";
        fg-col = mkLiteral "#C5CFF5";
        fg-col2 = mkLiteral "#F7768E";
        grey = mkLiteral "#B7BDF8";
        width = mkLiteral "550";
      };

      "element-text" = {
        "background-color" = mkLiteral "inherit";
        "text-color" = mkLiteral "inherit";
      };
      "element-icon" = {
        "background-color" = mkLiteral "inherit";
      };
      "mode-switcher" = {
        "background-color" = mkLiteral "inherit";
      };
      window = {
        "border-radius" = 12;
        height = 360;
        border = 3;
        "border-color" = mkLiteral "@border-col";
        "background-color" = mkLiteral "@bg-col";
      };
      mainbox = {
        "background-color" = mkLiteral "@bg-col";
      };
      inputbar = {
        children = map mkLiteral ["prompt" "entry"];
        "background-color" = mkLiteral "@bg-col";
        "border-radius" = 5;
        padding = 2;
      };
      prompt = {
        "background-color" = mkLiteral "@blue";
        padding = 6;
        "text-color" = mkLiteral "@bg-col";
        "border-radius" = 3;
        margin = mkLiteral "20px 0px 0px 20px";
      };
      "textbox-prompt-colon" = {
        expand = false;
        str = ":";
      };
      entry = {
        padding = 6;
        margin = mkLiteral "20px 0px 0px 10px";
        "text-color" = mkLiteral "@fg-col";
        "background-color" = mkLiteral "@bg-col";
      };
      listview = {
        border = mkLiteral "0px 0px 0px";
        padding = mkLiteral "6px 0px 0px";
        margin = mkLiteral "10px 0px 0px 20px";
        columns = 2;
        "background-color" = mkLiteral "@bg-col";
      };
      element = {
        padding = 5;
        "background-color" = mkLiteral "@bg-col";
        "text-color" = mkLiteral "@fg-col";
      };
      "element-icon" = {
        size = 25;
      };
      "element selected" = {
        "background-color" = mkLiteral "@selected-col";
        "text-color" = mkLiteral "@fg-col2";
      };
      "mode-switcher" = {
        spacing = 0;
      };
      button = {
        padding = 10;
        "background-color" = mkLiteral "@bg-col-light";
        "text-color" = mkLiteral "@grey";
        "vertical-align" = mkLiteral "0.5";
        "horizontal-align" = mkLiteral "0.5";
      };
      "button selected" = {
        "background-color" = mkLiteral "@bg-col";
        "text-color" = mkLiteral "@blue";
      };
    };
    programs.rofi.extraConfig = {
      modi = "run,drun,window";
      lines = 8;
      font = "Iosevka 10.5";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      terminal = "ghostty";
      drun-display-format = "{icon} {name}";
      location = 0;
      disable-history = false;
      hide-scrollbar = true;
      display-drun = "   Apps ";
      display-run = "   Run ";
      display-window = " 﩯  window";
      sidebar-mode = true;
    };
  };
}
