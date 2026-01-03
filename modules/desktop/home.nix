{
  lib,
  osConfig ? { },
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  config.dev = lib.intersectAttrs config.dev (osConfig.dev or { });
  options.desktop = {
    enable = mkEnableOption "all desktop tools";

    wm.enable = mkEnableOption "window manager and interface tools";
    terminal.enable = mkEnableOption "terminal tools";
    audio.enable = mkEnableOption "audio tools";
    apps.enable = mkEnableOption "desktop applications";
    browser.default = mkOption {
      description = "default browser xdg file";
      default = "firefox-devedition.desktop";
      type = types.str;
    };
    wallpaper = lib.mkOption {
      default = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/HoulFloof/wallpapers/f23c1010b93cb97baa7ad7c94fd552f7601496d2/misc/waves_right_colored.png";
        hash = "sha256-NqqE+pGnCIWAitH86sxu1EudVEEaSO82y3NqbhtDh9k=";
      };
      type = lib.types.path;
      description = "the wallpaper to use";
    };
  };
  imports = [
    ./wm
    ./terminal
    ./audio
    ./apps
  ];
}
