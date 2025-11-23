{
  config,
  inputs,
  inputs',
  username,
  ...
}: {
  users.users.${username} =
    if username != "root"
    then {
      home = "/home/${username}";
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "docker"
        "wheel"
      ];
    }
    else {};

  home-manager = {
    extraSpecialArgs = {inherit inputs inputs' username;};
    backupFileExtension = "bak";
    users.${username} = {
      home.username = username;
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
