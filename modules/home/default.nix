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
    users.${config.my.username} = {
      imports = [ inputs.catppuccin.homeModules.default ];

      home = {
        inherit (config.my) username;
        stateVersion = "25.11";
      };

      catppuccin = { inherit (config.catppuccin) flavor enable autoEnable; };

      manual = {
        html.enable = false;
        json.enable = false;
        manpages.enable = false;
      };
    };
  };
}
