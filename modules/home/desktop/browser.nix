{
  lib,
  osConfig,
  pkgs,
  ...
}: {
  options.browser.default = lib.mkOption {
    description = "default browser xdg file";
    default = "firefox-devedition.desktop";
    type = lib.types.str;
  };

  config = lib.mkIf osConfig.desktop.enable {
    home = {
      packages = [pkgs.firefox-devedition];
    };
  };
}
