{...}: {
  programs.home-manager.enable = true;
  home.username = "kar";
  home.homeDirectory = "/home/kar";
  home.stateVersion = "24.05";
  imports = [
    ../../common/fonts.nix
    ../../common/shell.nix

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
