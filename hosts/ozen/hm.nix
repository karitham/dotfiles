{inputs, ...}: {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.nixos = {
    imports = [
      ({pkgs, ...}: {
        programs.home-manager.enable = true;
        home.username = "nixos";
        home.stateVersion = "24.05";

        shell.name = "nu";
        shell.pkg = pkgs.nushell;
        catppuccin.enable = true;
        catppuccin.flavor = "macchiato";

        imports = [
          inputs.catppuccin.homeManagerModules.catppuccin
          ../../modules/fonts.nix
          ../../modules/shell.nix
          ../../modules/home/git.nix
          ../../modules/home/shell.nix
          ../../modules/home/helix.nix
        ];
      })
    ];
  };
}
