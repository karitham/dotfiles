{ config, lib, ... }:
{
  config = lib.mkIf config.dev.tools.enable {
    programs.yazi = {
      enable = true;
    };
  };
}
