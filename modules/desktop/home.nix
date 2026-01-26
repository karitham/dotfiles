{
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  config.desktop = {
    inherit (osConfig.desktop or { })
      enable
      wm
      waybar
      hyprlock
      wallpaper
      notification
      launcher
      terminal
      audio
      apps
      ;
  };
  options.desktop = {
    enable = mkEnableOption "all desktop tools";

    wm.enable = mkEnableOption "window manager and interface tools";
    waybar.enable = mkEnableOption "Waybar status bar";
    hyprlock.enable = mkEnableOption "Hyprlock screen locker";
    wallpaper.enable = mkEnableOption "Wallpaper management";
    wallpaper.image = lib.mkOption {
      default = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/HoulFloof/wallpapers/f23c1010b93cb97baa7ad7c94fd552f7601496d2/misc/waves_right_colored.png";
        hash = "sha256-NqqE+pGnCIWAitH86sxu1EudVEEaSO82y3NqbhtDh9k=";
      };
      type = lib.types.path;
      description = "the wallpaper to use";
    };
    notification.enable = mkEnableOption "Notification daemon";
    launcher.enable = mkEnableOption "Application launcher";
    terminal.enable = mkEnableOption "terminal tools";
    audio.enable = mkEnableOption "audio tools";
    apps.enable = mkEnableOption "desktop applications";
    browser.default = mkOption {
      description = "default browser xdg file";
      default = "firefox-devedition.desktop";
      type = types.str;
    };

  };
  imports = [
    ./wm
    ./terminal
    ./audio
    ./apps
  ];
}
