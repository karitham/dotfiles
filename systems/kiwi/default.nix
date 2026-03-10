{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./hardware.nix ];

  system.stateVersion = "25.11";

  desktop.noctalia.enable = true;
  home-manager.users.${config.my.username} = {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "hayase" ];

    home.packages = [
      pkgs.signal-desktop
      pkgs.obs-studio
      pkgs.hayase
    ];

    programs.waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";
  };

  boot = {
    # https://gitlab.freedesktop.org/drm/amd/-/issues/3925
    # https://gitlab.freedesktop.org/drm/amd/-/issues/3647
    # kernelParams = ["amdgpu.dcdebugmask=0x10"];

    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
  };
}
