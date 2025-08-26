{lib, ...}: {
  programs.waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";
  programs.zed-editor = {
    enable = true;
  };
}
