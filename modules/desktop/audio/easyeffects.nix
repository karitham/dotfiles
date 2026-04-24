{ lib, osConfig, ... }:
{
  config = lib.mkIf osConfig.desktop.audio.enable {
    xdg.dataFile."easyeffects/output".source = ./easyeffects;
    services.easyeffects = {
      enable = true;
    };
  };
}
