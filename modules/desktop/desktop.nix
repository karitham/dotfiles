{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.desktop;
in
{
  imports = [ inputs.niri.nixosModules.niri ];
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        wl-clipboard
        wlroots
        xdg-utils
        pavucontrol
        killall
        playerctl
        brightnessctl
        upower
        pulseaudio
        gnome-themes-extra
        mpv
      ];

      etc = {
        "xdg/gtk-3.0/settings.ini".text = ''
          [Settings]
          gtk-application-prefer-dark-theme=1
        '';
        "xdg/gtk-4.0/settings.ini".text = ''
          [Settings]
          gtk-application-prefer-dark-theme=1
        '';
      };
    };

    programs = {
      niri = {
        enable = true;
      };

      hyprlock = {
        enable = true;
      };
    };

    services = {
      upower.enable = true;
    };
  };
}
