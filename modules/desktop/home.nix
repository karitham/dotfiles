{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkIf
    mkEnableOption
    ;
in
{
  options.desktop = {
    enable = mkEnableOption "desktop tools";
    wm.enable = mkEnableOption "window manager";
    noctalia.enable = mkEnableOption "Noctalia shell";
    waybar.enable = mkEnableOption "Waybar status bar";
    hyprlock.enable = mkEnableOption "Hyprlock screen locker";
    wallpaper.enable = mkEnableOption "Wallpaper management";
    notification.enable = mkEnableOption "Notification daemon";
    launcher.enable = mkEnableOption "Application launcher";
    terminal.enable = mkEnableOption "terminal tools";
    audio.enable = mkEnableOption "audio tools";
    apps.enable = mkEnableOption "desktop applications";

    wallpaper.image = mkOption {
      default = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/HoulFloof/wallpapers/f23c1010b93cb97baa7ad7c94fd552f7601496d2/misc/waves_right_colored.png";
        hash = "sha256-NqqE+pGnCIWAitH86sxu1EudVEEaSO82y3NqbhtDh9k=";
      };
      type = lib.types.path;
      description = "the wallpaper to use";
    };
    browser.default = mkOption {
      description = "default browser xdg file";
      default = "helium.desktop";
      type = types.str;
    };
  };

  options.fonts = {
    mono = mkOption {
      type = types.str;
      default = "TX-02";
      description = "Global mono font for HM modules";
    };
  };

  config = {
    desktop.wm.enable = mkIf config.desktop.enable true;
    desktop.waybar.enable = mkIf (config.desktop.wm.enable && !config.desktop.noctalia.enable) true;
    desktop.hyprlock.enable = mkIf (config.desktop.wm.enable && !config.desktop.noctalia.enable) true;
    desktop.wallpaper.enable = mkIf (config.desktop.wm.enable && !config.desktop.noctalia.enable) true;
    desktop.notification.enable = mkIf (config.desktop.wm.enable && !config.desktop.noctalia.enable) true;
    desktop.launcher.enable = mkIf (config.desktop.wm.enable && !config.desktop.noctalia.enable) true;
    desktop.terminal.enable = mkIf config.desktop.enable true;
    desktop.audio.enable = mkIf config.desktop.enable true;
    desktop.apps.enable = mkIf config.desktop.enable true;
  };

  imports = [
    ./wm
    ./terminal
    ./audio
    ./apps
  ];
}
