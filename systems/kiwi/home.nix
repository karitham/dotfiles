{ pkgs, lib, ... }: {
  imports = [ ./handy.nix ];

  desktop.noctalia.enable = true;

  home.packages = [ pkgs.obsidian ];

  programs.waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";
}
