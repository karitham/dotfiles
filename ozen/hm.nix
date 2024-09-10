{
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

        imports = [
          ../common/home/git.nix
          ../common/home/shell.nix
          ../common/home/helix.nix
          ../common/fonts.nix
          ../common/shell.nix
        ];
      })
    ];
  };
}
