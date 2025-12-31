{ lib, config, ... }:
{
  config = lib.mkIf config.desktop.apps.enable { programs.vesktop.enable = true; };
}
