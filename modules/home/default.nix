{
  config,
  inputs,
  ...
}: {
  users.users.${inputs.username} =
    if inputs.username != "root"
    then {
      home = "/home/${inputs.username}";
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "docker"
        "wheel"
      ];
    }
    else {};

  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    backupFileExtension = "bak";
    users.${inputs.username} = {
      home.username = inputs.username;
      home.stateVersion = "24.11";

      catppuccin = {
        inherit (config.catppuccin) enable;
        inherit (config.catppuccin) flavor;
      };

      imports = [
        ../nixos/overlays
        inputs.catppuccin.homeManagerModules.catppuccin

        ./hyprland.nix
        ./hyprlock.nix
        ./waybar.nix
        ./rofi.nix
        ./ghostty.nix
        ./spotify.nix
        ./git.nix
        ./jj.nix
        ./shell.nix
        ./atuin.nix
        ./helix.nix
        ./rnnoise.nix
        ./file-manager.nix
        ./browser.nix
      ];
    };
  };
}
