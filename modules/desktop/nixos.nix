{ config, lib, ... }:
let
  cfg = config.desktop;
  inherit (lib) mkIf mkEnableOption;
in
{
  imports = [
    ../options/desktop.nix
    ./desktop.nix
    ./sound.nix
    ./yubikey.nix
    ./fonts.nix
    ./locale.nix
    ./ipcam.nix
  ];

  options.desktop = {
    ipcam.enable = mkEnableOption "IP camera support";
    yubikey.enable = mkEnableOption "YubiKey support";
    locale.enable = mkEnableOption "locale and timezone settings";
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.waybar.enable && cfg.noctalia.enable);
        message = "Cannot enable both Waybar and Noctalia at the same time.";
      }
    ];

    desktop.yubikey.enable = mkIf cfg.enable true;
    desktop.locale.enable = mkIf cfg.enable true;
  };
}
