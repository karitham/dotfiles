{ config, self, ... }:
{
  imports = [
    self.nixosModules.desktop
    self.nixosModules.dev
    ../locale.nix
    ../nixos/desktop-common.nix
    ../hardware/peripherals.nix
  ];

  desktop.enable = true;
  dev.enable = true;

  home-manager.users.${config.my.username}.imports = [
    self.homeModules.desktop
    self.homeModules.dev
  ];
}
