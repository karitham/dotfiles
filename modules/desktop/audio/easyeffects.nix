{ lib, config, ... }:
{
  config = lib.mkIf config.desktop.audio.enable {
    xdg.dataFile."easyeffects/output".source = ./easyeffects;
    services.easyeffects = {
      enable = true;
    };
  };
}
