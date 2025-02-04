{
  pkgs,
  inputs,
  ...
}: {
  nix.registry = {
    k.flake = inputs.knixpkgs;
  };
  nix.settings = {
    trusted-users = ["root" "kar"];
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
  };
  nixpkgs = {
    overlays = [
      (import ../overlays/gotools.nix {})
    ];
    config = {
      allowUnfree = true;
      input-fonts.acceptLicense = true;
    };
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
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/kar/dotfiles";
  };

  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    inputs.home-manager.nixosModules.home-manager
    ../common/home

    ../common/fonts.nix
    ../common/shell.nix
    ../common/nixos/greetd.nix
    ../common/nixos/ipcam.nix
    ./hardware.nix
    ./configuration.nix
  ];

  home-manager.users.kar.imports = [./home-upf.nix ./desktop.nix];
}
