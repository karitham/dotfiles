{
  home-manager,
  pkgs,
  knixpkgs,
  catppuccin,
  zen-browser,
  ...
}: {
  nix.registry = {
    k.flake = knixpkgs;
  };
  catppuccin.enable = true;
  catppuccin.flavor = "macchiato";
  shell.name = "nu";
  shell.pkg = pkgs.nushell;

  system = {stateVersion = "24.11";};
  environment.systemPackages = [
    zen-browser.packages."${pkgs.system}"
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };
  imports = [
    ../common/fonts.nix
    ../common/shell.nix
    ../common/nixos/ipcam.nix
    ../common/desktop/desktop.nix
    ../common/desktop/greetd.nix

    ./hardware.nix
    ./configuration.nix
    catppuccin.nixosModules.catppuccin
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.kar = {
        shell.name = "nu";
        shell.pkg = pkgs.nushell;
        catppuccin.enable = true;
        catppuccin.flavor = "macchiato";
        imports = [
          ../common/desktop/home
          catppuccin.homeManagerModules.catppuccin
          ./home-upf.nix
          ./desktop.nix
        ];
      };
    }
  ];
}
