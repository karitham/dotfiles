{
  config,
  inputs,
  inputs',
  self,
  self',
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.default
    inputs.catppuccin.nixosModules.catppuccin
  ];

  documentation.enable = false;

  catppuccin = {
    enable = true;
    flavor = "macchiato";
    autoEnable = true;
    cache.enable = true;
  };

  home-manager = {
    useGlobalPkgs = true;

    extraSpecialArgs = {
      inherit
        inputs
        inputs'
        self
        self'
        ;
    };
    backupFileExtension = "bak";
    users.${config.my.username}.imports = [ ./common.nix ];
  };
}
