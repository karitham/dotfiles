{
  config,
  lib,
  pkgs,
  inputs,
  inputs',
  ...
}:
let
  cfg = config.desktop;
in
{
  imports = [ inputs.niri.nixosModules.niri ];
  config = lib.mkIf cfg.wm.enable {
    environment = {
      systemPackages = with pkgs; [
        wl-clipboard
        xdg-utils
        pavucontrol
        playerctl
        brightnessctl
        upower
        pulseaudio
        gnome-themes-extra
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
        package = inputs'.niri.packages.niri-unstable;
      };
      hyprlock.enable = cfg.hyprlock.enable;
    };

    services = {
      upower.enable = true;
    };
  };
}
