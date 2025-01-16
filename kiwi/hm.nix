{
  inputs,
  pkgs,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users.kar = {
      shell.name = "nu";
      shell.pkg = pkgs.nushell;
      catppuccin.enable = true;
      catppuccin.flavor = "macchiato";
      imports = [
        ../common/desktop/home
        inputs.catppuccin.homeManagerModules.catppuccin
        ./home-upf.nix
        ./desktop.nix
      ];
    };
  };
}
