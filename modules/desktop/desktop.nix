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

      etc = lib.genAttrs [ "xdg/gtk-3.0/settings.ini" "xdg/gtk-4.0/settings.ini" ] (_: {
        text = ''
          [Settings]
          gtk-application-prefer-dark-theme=1
        '';
      });
    };

    programs = {
      niri.enable = true;
      niri.package = inputs'.niri.packages.niri-unstable;
      hyprlock.enable = cfg.hyprlock.enable;
    };

    services = {
      upower.enable = true;
      gnome.gnome-keyring.enable = true;
    };
  };
}
