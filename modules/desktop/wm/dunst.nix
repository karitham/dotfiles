{ config, ... }:
{
  services.dunst.enable = config.desktop.wm.enable;
}
