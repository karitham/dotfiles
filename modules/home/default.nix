{
  config,
  inputs,
  inputs',
  self,
  self',
  ...
}: {
  imports = [inputs.home-manager.nixosModules.default];
  users.users.${config.my.username} =
    if config.my.username != "root"
    then {
      home = "/home/${config.my.username}";
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "docker"
        "wheel"
      ];
    }
    else {};

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
      home.username = config.my.username;
      home.stateVersion = "25.11";

      catppuccin = {
        inherit (config.catppuccin) enable;
        inherit (config.catppuccin) flavor;
      };

      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.niri.overlays.niri
        inputs.ghostty.overlays.default
        inputs.knixpkgs.overlays.default
      ];

      imports = [
        inputs.catppuccin.homeModules.default
        ./desktop
        ./dev
      ];
    };
  };
}
