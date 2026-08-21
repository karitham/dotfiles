{ lib, config, ... }: {
  config = lib.mkIf config.dev.enable {
    virtualisation.docker = {
      enable = lib.mkDefault true;
      enableOnBoot = false;
      daemon.settings = {
        shutdown-timeout = 2;
      };
    };
  };
}
