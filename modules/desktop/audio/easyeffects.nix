{ lib, config, ... }: {
  config = lib.mkIf config.desktop.enable {
    xdg.dataFile."easyeffects/output".source = ./easyeffects;
    services.easyeffects = {
      enable = true;
    };
  };
}
