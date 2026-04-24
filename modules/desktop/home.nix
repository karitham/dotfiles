{ lib, pkgs, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.desktop = {
    wallpaper.image = lib.mkOption {
      default = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/HoulFloof/wallpapers/f23c1010b93cb97baa7ad7c94fd552f7601496d2/misc/waves_right_colored.png";
        hash = "sha256-NqqE+pGnCIWAitH86sxu1EudVEEaSO82y3NqbhtDh9k=";
      };
      type = lib.types.path;
      description = "the wallpaper to use";
    };
    browser.default = mkOption {
      description = "default browser xdg file";
      default = "helium.desktop";
      type = types.str;
    };
  };

  imports = [
    ./wm
    ./terminal
    ./audio
    ./apps
  ];
}
