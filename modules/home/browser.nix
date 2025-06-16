{
  lib,
  osConfig,
  inputs',
  pkgs,
  ...
}: {
  options.browser.default = lib.mkOption {
    description = "default browser xdg file";
    default = "zen.desktop"; # firefox-devedition.desktop
    type = lib.types.str;
  };

  config = lib.mkIf osConfig.desktop.enable {
    home = let
      catppuccin = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "zen-browser";
        rev = "b048e8bd54f784d004812036fb83e725a7454ab4";
        hash = "sha256-SoaJV83rOgsQpLKO6PtpTyKFGj75FssdWfTITU7psXM=";
      };
      zenConfigPath = ".zen";
      firefoxConfigPath = "${zenConfigPath}";
      profilesPath = firefoxConfigPath;
      profiles = {
        Profile0 = {
          Name = "kar";
          Path = "kar.default";
          IsRelative = 1;
          Default = 1;
          ZenAvatarPath = "${catppuccin}/themes/Macchiato/Mauve/zen-logo-macchiato.svg";
        };
        General = {
          StartWithLastProfile = 1;
          Version = 2;
        };
      };
    in {
      packages = [inputs'.zen-browser.packages.default pkgs.firefox-devedition];
      file = {
        "${firefoxConfigPath}/profiles.ini".text = lib.generators.toINI {} profiles;
        "${profilesPath}/${profiles.Profile0.Path}/chrome/userChrome.css".source = "${catppuccin}/themes/Macchiato/Mauve/userChrome.css";
        "${profilesPath}/${profiles.Profile0.Path}/chrome/userContent.css".source = "${catppuccin}/themes/Macchiato/Mauve/userContent.css";
      };
    };
  };
}
