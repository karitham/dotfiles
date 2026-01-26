{ config, lib, ... }:
let
  cfg = config.desktop;
  inherit (lib) mkIf mkEnableOption;
in
{
  options.desktop = {
    enable = mkEnableOption "all desktop tools";

    wm.enable = mkEnableOption "window manager and interface tools";
    waybar.enable = mkEnableOption "Waybar status bar";
    hyprlock.enable = mkEnableOption "Hyprlock screen locker";
    wallpaper.enable = mkEnableOption "Wallpaper management";
    notification.enable = mkEnableOption "Notification daemon";
    launcher.enable = mkEnableOption "Application launcher";
    terminal.enable = mkEnableOption "terminal tools";
    audio.enable = mkEnableOption "audio tools";
    apps.enable = mkEnableOption "desktop applications";
    ipcam.enable = mkEnableOption "IP camera support";
    yubikey.enable = mkEnableOption "YubiKey support";
    locale.enable = mkEnableOption "locale and timezone settings";
  };

  imports = [
    ./desktop.nix
    ./sound.nix
    ./yubikey.nix
    ./fonts.nix
    ./locale.nix
    ./ipcam.nix
  ];

  config = {
    desktop.wm.enable = mkIf cfg.enable true;
    desktop.waybar.enable = mkIf cfg.wm.enable true;
    desktop.hyprlock.enable = mkIf cfg.wm.enable true;
    desktop.wallpaper.enable = mkIf cfg.wm.enable true;
    desktop.notification.enable = mkIf cfg.wm.enable true;
    desktop.launcher.enable = mkIf cfg.wm.enable true;
    desktop.terminal.enable = mkIf cfg.enable true;
    desktop.audio.enable = mkIf cfg.enable true;
    desktop.apps.enable = mkIf cfg.enable true;
    desktop.yubikey.enable = mkIf cfg.enable true;
    desktop.locale.enable = mkIf cfg.enable true;
  };
}
