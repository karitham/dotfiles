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

  # Block outgoing UDP from Tailscale CGNAT addresses on non-tailscale interfaces.
  # Prevents WebRTC (e.g. Discord voice) from selecting a broken ICE candidate
  # that uses the Tailscale IP — responses can't route back to 100.x addresses.
  networking.firewall.extraCommands = ''
    iptables -A OUTPUT -p udp -s 100.64.0.0/10 ! -o tailscale0 -j DROP
  '';

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
