{
  lib,
  osConfig,
  pkgs,
  ...
}: {
  config = lib.mkIf osConfig.desktop.enable {
    home.packages = [pkgs.legcord];
    xdg.configFile."legcord/quickCss.css".text = ''
      @import url("https://catppuccin.github.io/discord/dist/catppuccin-macchiato.theme.css");
    '';
  };
}
