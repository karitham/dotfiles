{ config, lib, ... }:
let
  cfg = config.desktop;
  inherit (lib) mkIf mkEnableOption;
in
{
  imports = [
    ./desktop.nix
    ./sound.nix
    ./yubikey.nix
    ./fonts.nix
  ];

  options.desktop = {
    enable = mkEnableOption "desktop tools";
    yubikey.enable = mkEnableOption "YubiKey support";
  };

  config.desktop.yubikey.enable = mkIf cfg.enable true;
}
