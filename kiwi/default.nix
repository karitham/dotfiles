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
    ../common/home

    ../common/fonts.nix
    ../common/shell.nix
    ../common/nixos/greetd.nix
    ../common/nixos/ipcam.nix
    ../common/nixos/nix.nix
    ./hardware.nix
    ./configuration.nix
  ];

  home-manager.users.kar.imports = [./home-upf.nix ./desktop.nix];
}
