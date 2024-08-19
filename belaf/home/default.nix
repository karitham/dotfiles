{...}: {
  programs.home-manager.enable = true;
  home.username = "kar";
  home.homeDirectory = "/home/kar";
  home.stateVersion = "24.05";

  xdg.mimeApps = {
    enable = true;
    associations.added = {
      "x-scheme-handler/http" = ["firefox.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop"];
      "x-scheme-handler/chrome" = ["firefox.desktop"];
      "text/html" = ["firefox.desktop"];
      "application/x-extension-htm" = ["firefox.desktop"];
      "application/x-extension-html" = ["firefox.desktop"];
      "application/x-extension-shtml" = ["firefox.desktop"];
      "application/xhtml+xml" = ["firefox.desktop"];
      "application/x-extension-xhtml" = ["firefox.desktop"];
      "application/x-extension-xht" = ["firefox.desktop"];
    };
    defaultApplications = {
      "x-scheme-handler/http" = ["firefox.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop"];
      "x-scheme-handler/chrome" = ["firefox.desktop"];
      "text/html" = ["firefox.desktop"];
      "application/x-extension-htm" = ["firefox.desktop"];
      "application/x-extension-html" = ["firefox.desktop"];
      "application/x-extension-shtml" = ["firefox.desktop"];
      "application/xhtml+xml" = ["firefox.desktop"];
      "application/x-extension-xhtml" = ["firefox.desktop"];
      "application/x-extension-xht" = ["firefox.desktop"];
    };
  };

  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./rofi.nix
    ./ghostty.nix
    ../../common/home/git.nix
    ../../common/home/shell.nix
    ../../common/home/helix.nix
    ../../common/home/modules/ghostty.nix
  ];

  services.dunst.enable = true;
}
