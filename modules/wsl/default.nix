{
  inputs,
  self,
  config,
  ...
}:
{
  imports = [
    self.nixosModules.dev
    inputs.nixos-wsl.nixosModules.default
    ../locale.nix
    ../home
  ];

  dev.enable = true;

  home-manager.users.${config.my.username}.imports = [ self.homeModules.dev ];
}
