{ config, ... }: { services.dunst.enable = config.desktop.enable && !config.desktop.noctalia.enable; }
