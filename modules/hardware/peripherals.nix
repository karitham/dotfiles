{ pkgs, ... }:
{
  hardware.bluetooth.enable = true;
  hardware.keyboard.qmk.enable = true;
  services.udev.packages = with pkgs; [ via ];
}
