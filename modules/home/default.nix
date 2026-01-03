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
  };

  home-manager = {
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

      catppuccin = { inherit (config.catppuccin) flavor enable; };

      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.niri.overlays.niri
        inputs.ghostty.overlays.default
        inputs.knixpkgs.overlays.default
      ];

      manual = {
        html.enable = false;
        json.enable = false;
        manpages.enable = false;
      };
    };
  };
}
