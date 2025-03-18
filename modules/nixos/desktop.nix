{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.desktop;
in {
  options.desktop = let
    defaultWallpaper = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/HoulFloof/wallpapers/f23c1010b93cb97baa7ad7c94fd552f7601496d2/misc/waves_right_colored.png";
      hash = "sha256-NqqE+pGnCIWAitH86sxu1EudVEEaSO82y3NqbhtDh9k=";
    };
  in {
    enable =
      lib.mkEnableOption "desktop usage"
      // {
        default = lib.lists.any (isTrue: isTrue == true) [cfg.hyprland cfg.niri];
      };
    wallpaper = lib.mkOption {
      default = "${defaultWallpaper}";
      type = lib.types.path;
      description = "the wallpaper to use";
    };
    hyprland = lib.mkEnableOption "enable hyprland";
    niri = lib.mkEnableOption "enable niri";
  };

  config = let
    wms = (lib.optional cfg.hyprland pkgs.hyprland) ++ (lib.optional cfg.niri pkgs.niri);
  in
    lib.mkIf cfg.enable {
      hardware = {
        bluetooth.enable = true;
      };

      environment = {
        systemPackages = with pkgs;
          [
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
          ]
          ++ wms;

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
        hyprland = lib.mkIf cfg.hyprland {
          enable = true;
          xwayland.enable = true;
          withUWSM = true;
        };

        hyprlock = {
          enable = true;
        };
      };

      services = {
        upower.enable = true;
        greetd = let
          tuigreet = lib.getExe pkgs.greetd.tuigreet;
          wm = lib.meta.getExe (builtins.head wms);
        in {
          enable = true;
          vt = 7; # # tty to skip startup messages
          settings = {
            default_session.command = ''
              ${tuigreet} \
                --time \
                --asterisks \
                --remember \
                --cmd ${wm}
            '';
          };
        };
      };
    };
}
