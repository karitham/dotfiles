{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.nixos = {
    imports = [
      ({...}: {
        programs.home-manager.enable = true;
        home.username = "nixos";
        home.stateVersion = "24.05";

        imports = [
          ../common/home/git.nix
          ../common/home/shell.nix
          ../common/home/helix.nix
        ];
      })
      ../common/fonts.nix
    ];
  };
}
