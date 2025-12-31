{ config, lib, ... }:
{
  services.dunst = lib.mkIf config.desktop.wm.enable { enable = true; };
}
