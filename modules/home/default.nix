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
        inputs.niri.overlays.niri
        inputs.ghostty.overlays.default
      ];

      imports = [
        inputs.catppuccin.homeModules.default

        ./atuin.nix
        ./browser.nix
        ./cursor.nix
        ./direnv.nix
        ./discord.nix
        ./dunst.nix
        ./fuzzel.nix
        ./ghostty.nix
        ./git.nix
        ./helix.nix
        ./hyprpaper.nix
        ./hyprland.nix
        ./hyprlock.nix
        ./jj.nix
        ./mise.nix
        ./niri.nix
        ./rnnoise.nix
        ./shell.nix
        ./spotify.nix
        ./starship.nix
        ./waybar.nix
        ./xdg.nix
        ./yazi.nix
        ./zellij.nix
      ];
    };
  };
}
