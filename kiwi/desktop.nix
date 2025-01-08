{lib, ...}: {
  programs.waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "HDMI-A-1, preferred, auto-left, 1"
    ];
  };
}
