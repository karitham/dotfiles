{ osConfig, lib, ... }:
{
  config = lib.mkIf osConfig.dev.tools.enable {
    programs.yazi = {
      enable = true;
    };
  };
}
