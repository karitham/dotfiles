{
  config,
  lib,
  pkgs,
  ...
}:
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
        url = "https://raw.githubusercontent.com/HoulFloof/wallpapers/f23c1010b93cb97baa7ad7c94fd552f7601496d2/misc/waves_right_colored.png";
        hash = "sha256-NqqE+pGnCIWAitH86sxu1EudVEEaSO82y3NqbhtDh9k=";
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
