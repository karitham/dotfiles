{ config, ... }:
{
  services.dunst.enable = config.desktop.notification.enable;
}
