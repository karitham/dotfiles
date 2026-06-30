{
  config,
  lib,
  self,
  ...
}:
{
  config = lib.mkIf config.desktop.enable {
    desktop.yubikey.enable = true;
    programs._1password.enable = true;
    services.ninjaone.enable = true;

    home-manager.users.${config.my.username}.imports = [ self.homeModules.work ];
  };
}
