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
      home.stateVersion = "24.11";

      catppuccin = {
        inherit (config.catppuccin) enable;
        inherit (config.catppuccin) flavor;
      };

      nixpkgs.overlays = [
        inputs.self.overlays.default
      ];

      imports = [
        inputs.catppuccin.homeManagerModules.catppuccin

        ./hyprland.nix
        ./niri.nix
        ./hyprlock.nix
        ./cursor.nix
        ./waybar.nix
        ./dunst.nix
        ./discord.nix
        # ./rofi.nix
        ./fuzzel.nix
        ./ghostty.nix
        ./spotify.nix
        ./git.nix
        ./jj.nix
        ./shell.nix
        ./atuin.nix
        ./helix.nix
        ./rnnoise.nix
        ./zellij.nix
        ./browser.nix
        ./direnv.nix
      ];
    };
  };
}
