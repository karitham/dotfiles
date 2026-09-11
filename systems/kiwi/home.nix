{ pkgs, lib, ... }: {
  imports = [ ./handy.nix ];

  desktop.noctalia.enable = true;

  home.packages = [
    pkgs.obs-studio
    pkgs.zed-editor # trying out zed for code review
  ];

  programs.waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";
}
