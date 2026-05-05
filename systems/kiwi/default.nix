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
    home.packages = [ pkgs.obs-studio ];

    programs.waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";
    imports = [ ./handy.nix ];
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
