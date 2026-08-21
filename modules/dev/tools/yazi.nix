{ config, lib, ... }: {
  config = lib.mkIf config.dev.enable {
    programs.yazi = {
      enable = true;
    };
  };
}
