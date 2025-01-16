{...}: {
  programs.home-manager.enable = true;
  home.username = "kar";
  home.homeDirectory = "/home/kar";
  home.stateVersion = "24.05";
  imports = [
    ../../fonts.nix
    ../../shell.nix

    ./hyprland.nix
    ./waybar.nix
    ./rofi.nix
    ./ghostty.nix
    ./spotify.nix
    ../../home/git.nix
    ../../home/shell.nix
    ../../home/helix.nix
  ];

  services.dunst.enable = true;
}
