{ lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    mkEnableOption
    mkDefault
    ;
in
{
  options.desktop = {
    enable = mkEnableOption "desktop tools";
    noctalia.enable = mkEnableOption "Noctalia shell";

    wallpaper.image = mkOption {
      default = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/8g/wallhaven-8g9kxk.jpg";
        hash = "sha256-/KXb7sf2w0EgL20CWHIAzraS6ax6Bmqtu//zS6wp9jE=";
      };
      type = types.path;
      description = "the wallpaper to use";
    };
    browser.default = mkOption {
      description = "default browser xdg file";
      default = "helium.desktop";
      type = types.str;
    };
  };

  options.fonts = {
    mono = mkOption {
      type = types.str;
      default = "TX-02";
      description = "Global mono font for HM modules";
    };
  };

  # Noctalia replaces the waybar/hyprlock/wallpaper/notification/launcher
  # stack when enabled; individual components derive their activation from
  # these two options at their point of use.
  config.desktop.enable = mkDefault true;

  imports = [
    ./wm
    ./terminal
    ./audio
    ./apps
  ];
}
