{
  pkgs,
  inputs,
  ...
}: {
  nix.registry = {
    k.flake = inputs.knixpkgs;
  };
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
    # portalPackage = pkgs.xdg-desktop-portal-wlr;
  };

  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    inputs.home-manager.nixosModules.home-manager
    ../common/fonts.nix
    ../common/shell.nix
    ../common/nixos/ipcam.nix
    ../common/desktop/desktop.nix
    ../common/desktop/greetd.nix

    ./hm.nix
    ./hardware.nix
    ./configuration.nix
  ];
}
