{ pkgs, lib, ... }: {
  imports = [ ./handy.nix ];

  desktop.noctalia.enable = true;

  dev.albedo.enable = true;
  # Same shape as ozen: the daemon keeps the threads alive while the app is
  # closed and answers the tailnet. The app here is a client of it, not the
  # owner of its home.
  dev.t3code = {
    enable = true;
    appLocalEnvironment = false;
    daemon = {
      enable = true;
      expose = true;
    };
  };

  dev.gallant.local = {
    enable = true;
    package = pkgs.callPackage ../../pkgs/llama-cpp-d1/package.nix { vulkanSupport = true; };
    gpuLayers = 99;
  };

  home.packages = [ pkgs.obsidian ];

  programs.waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";
}
