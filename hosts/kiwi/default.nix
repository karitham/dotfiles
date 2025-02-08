{
  pkgs,
  inputs,
  ...
}: {
  catppuccin.enable = true;
  catppuccin.flavor = "macchiato";
  shell.name = "nu";
  shell.pkg = pkgs.nushell;

  system = {stateVersion = "24.11";};
  environment.systemPackages = [
    inputs.zen-browser.packages."${pkgs.system}".default
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    inputs.home-manager.nixosModules.home-manager
    ../../modules/home

    ../../modules/fonts.nix
    ../../modules/shell.nix
    ../../modules/nixos/greetd.nix
    ../../modules/nixos/ipcam.nix
    ../../modules/nixos/nix.nix
    ./hardware.nix
    ./configuration.nix
  ];

  home-manager.users.kar.imports = [./home-upf.nix ./desktop.nix];
}
