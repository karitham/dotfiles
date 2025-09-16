{
  lib,
  pkgs,
  ...
}: {
  home.packages = [
    pkgs.opencode
    pkgs.signal-desktop-bin
    pkgs.obs-studio
  ];

  programs = {
    waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";

    zed-editor = {
      enable = true;
    };
  };
}
