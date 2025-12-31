{ lib, config, ... }:
{
  config = lib.mkIf config.desktop.audio.enable {
    xdg.configFile."easyeffects/output".source = ./easyeffects;
    services.easyeffects = {
      enable = true;
    };
  };
}
