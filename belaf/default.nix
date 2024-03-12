{
  hyprland,
  home-manager,
  knixpkgs,
  catppuccin,
  ...
}: {
  nix.registry = {
    k.flake = knixpkgs;
  };
  catppuccin.enable = true;
  catppuccin.flavor = "macchiato";
  system = {stateVersion = "24.05";};
  imports = [
    ./hardware.nix
    ./desktop.nix
    ./configuration.nix
    ./fabric.nix
    catppuccin.nixosModules.catppuccin
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.kar = {
        imports = [./home catppuccin.homeManagerModules.catppuccin];
        catppuccin.enable = true;
        catppuccin.flavor = "macchiato";
      };
    }
    hyprland.nixosModules.default
    {programs.hyprland.enable = true;}
    ./greetd.nix
  ];
}
