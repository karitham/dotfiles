{ pkgs, lib, ... }: {
  imports = [ ./handy.nix ];

  dev.enable = true;
  desktop.enable = true;
  desktop.noctalia.enable = true;

  home.packages = [ pkgs.obs-studio ];

  programs.waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";
}
