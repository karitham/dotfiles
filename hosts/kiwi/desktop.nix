{lib, ...}: {
  programs.waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1, preferred, 0x0, 1"
      "HDMI-A-1, preferred, auto-left, 1"
    ];
  };
}
