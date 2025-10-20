{
  lib,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "hayase"
    ];
  home.packages = [
    pkgs.signal-desktop-bin
    pkgs.obs-studio
    pkgs.hayase
  ];

  programs = {
    waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";

    zed-editor = {
      enable = true;
    };
  };
}
