{
  inputs,
  pkgs,
  ...
}: {
  catppuccin.enable = true;
  catppuccin.flavor = "macchiato";

  services.upower.enable = true;
  environment = with pkgs; {
    systemPackages = [
      wl-clipboard
      waybar
      wlroots
      dunst
      xdg-utils
      pavucontrol
      killall
      playerctl
      brightnessctl
      upower
      pulseaudio
      gnome-themes-extra
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users.kar = {
      home.username = "kar";
      home.homeDirectory = "/home/kar";
      home.stateVersion = "24.05";
      shell.name = "nu";
      catppuccin.enable = true;
      catppuccin.flavor = "macchiato";

      imports = [
        ../fonts.nix
        ../shell.nix
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
      ];
    };
  };
}
