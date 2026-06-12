{ osConfig, ... }: { services.dunst.enable = osConfig.desktop.notification.enable; }
