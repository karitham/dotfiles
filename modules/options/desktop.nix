{ config, lib, ... }:
let
  cfg = config.desktop;
  inherit (lib) mkEnableOption mkIf;

  sharedOptions = {
    enable = mkEnableOption "all desktop tools";
    wm.enable = mkEnableOption "window manager and interface tools";
    noctalia.enable = mkEnableOption "Noctalia Shell";
    waybar.enable = mkEnableOption "Waybar status bar";
    hyprlock.enable = mkEnableOption "Hyprlock screen locker";
    wallpaper.enable = mkEnableOption "Wallpaper management";
    notification.enable = mkEnableOption "Notification daemon";
    launcher.enable = mkEnableOption "Application launcher";
    terminal.enable = mkEnableOption "terminal tools";
    audio.enable = mkEnableOption "audio tools";
    apps.enable = mkEnableOption "desktop applications";
  };
in
{
  options.desktop = sharedOptions;

  config = {
    desktop.wm.enable = mkIf cfg.enable true;
    # Default to Waybar if Noctalia is not explicitly enabled for now
    desktop.waybar.enable = mkIf (cfg.wm.enable && !cfg.noctalia.enable) true;
    desktop.hyprlock.enable = mkIf (cfg.wm.enable && !cfg.noctalia.enable) true;
    desktop.wallpaper.enable = mkIf (cfg.wm.enable && !cfg.noctalia.enable) true;
    desktop.notification.enable = mkIf (cfg.wm.enable && !cfg.noctalia.enable) true;
    desktop.launcher.enable = mkIf (cfg.wm.enable && !cfg.noctalia.enable) true;
    desktop.terminal.enable = mkIf cfg.enable true;
    desktop.audio.enable = mkIf cfg.enable true;
    desktop.apps.enable = mkIf cfg.enable true;

    home-manager.sharedModules = [
      {
        options.desktop = sharedOptions;
        config.desktop = {
          enable = cfg.enable;
          wm.enable = cfg.wm.enable;
          noctalia.enable = cfg.noctalia.enable;
          waybar.enable = cfg.waybar.enable;
          hyprlock.enable = cfg.hyprlock.enable;
          wallpaper.enable = cfg.wallpaper.enable;
          notification.enable = cfg.notification.enable;
          launcher.enable = cfg.launcher.enable;
          terminal.enable = cfg.terminal.enable;
          audio.enable = cfg.audio.enable;
          apps.enable = cfg.apps.enable;
        };
      }
    ];
  };
}
