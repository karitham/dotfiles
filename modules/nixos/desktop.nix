{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.desktop;
in {
  options.desktop = {
    enable = lib.mkEnableOption "desktop usage";
    wallpaper = lib.mkOption {
      default = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/HoulFloof/wallpapers/f23c1010b93cb97baa7ad7c94fd552f7601496d2/misc/waves_right_colored.png";
        hash = "sha256-NqqE+pGnCIWAitH86sxu1EudVEEaSO82y3NqbhtDh9k=";
      };
      type = lib.types.path;
      description = "the wallpaper to use";
    };
  };

  imports = [inputs.niri.nixosModules.niri];

  config = lib.mkIf cfg.enable {
    hardware = {
      bluetooth.enable = true;
    };

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
