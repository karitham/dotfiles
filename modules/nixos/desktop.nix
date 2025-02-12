{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.desktop;
in {
  options.desktop = {
    enable = lib.mkEnableOption "desktop usage";
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      bluetooth.enable = true;
    };

    virtualisation.docker.enable = true;

    environment = {
      systemPackages = with pkgs; [
        wl-clipboard
        waybar
        wlroots
        dunst
        xdg-utils
        pavucontrol
        killall
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
        "greetd/environments".text = ''
          hyprland
        '';
      };
    };

    programs = {
      hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };
    };

    services = {
      upower.enable = true;
      greetd = {
        enable = true;
        vt = 7; # # tty to skip startup msgs
        settings = {
          default_session.command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet \
              --time \
              --asterisks \
              --user-menu \
              --cmd Hyprland
          '';
        };
      };
    };
  };
}
