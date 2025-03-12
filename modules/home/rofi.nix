{
  config,
  pkgs,
  osConfig,
  lib,
  ...
}: {
  config = lib.mkIf osConfig.desktop.enable {
    services.dunst.enable = true;
    programs.rofi = {
      package = pkgs.rofi-wayland;
      enable = true;
      extraConfig = {
        modi = "run,drun,window";
        lines = 8;
        font = "${osConfig.fonts.mono} 10.5";
        show-icons = true;
        icon-theme = "Papirus-Dark";
        terminal = "ghostty";
        drun-display-format = "{icon} {name}";
        location = 0;
        disable-history = false;
        hide-scrollbar = true;
        display-drun = "   Apps ";
        display-run = "   Run ";
        display-window = " 﩯 Window";
        sidebar-mode = true;
      };
    };
  };
}
