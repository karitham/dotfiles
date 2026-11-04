{ pkgs, lib, ... }: {
  imports = [ ./handy.nix ];

  desktop.noctalia.enable = true;

  dev.albedo.enable = true;

  dev.gallant.local = {
    enable = true;
    package = pkgs.callPackage ../../pkgs/llama-cpp-d1/package.nix { vulkanSupport = true; };
    gpuLayers = 99;
  };

  home.packages = [ pkgs.obsidian ];

  programs.waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";
}
