{
  config,
  lib,
  inputs,
  ...
}: {
  options.hm.enable = lib.mkEnableOption "Enable home manager";

  config = {
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

    home-manager = lib.mkIf config.hm.enable {
      extraSpecialArgs = {
        inherit inputs;
      };
      users.${inputs.username} = {
        home.username = inputs.username;
        home.stateVersion = "24.05";

        catppuccin = {
          enable = config.catppuccin.enable;
          flavor = config.catppuccin.flavor;
        };

        imports = [
          inputs.catppuccin.homeManagerModules.catppuccin

          ./hyprland.nix
          ./waybar.nix
          ./rofi.nix
          ./ghostty.nix
          ./spotify.nix
          ./git.nix
          ./shell.nix
          ./helix.nix
          ./rnnoise.nix
          ./file-manager.nix
        ];
      };
    };
  };
}
