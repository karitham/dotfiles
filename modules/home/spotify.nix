{
  osConfig,
  lib,
  inputs',
  ...
}: {
  imports = [inputs'.spicetify-nix.homeManagerModules.default];
  config = lib.mkIf osConfig.desktop.enable {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["spotify"];

    programs.spicetify = {
      enable = true;
      enabledExtensions = with inputs'.spicetify-nix.legacyPackages.extensions; [
        adblock
        hidePodcasts
        shuffle # shuffle+ (special characters are sanitized out of extension names)
      ];
      theme = inputs'.spicetify-nix.legacyPackages.themes.catppuccin;
      colorScheme = "macchiato";
    };
  };
}
