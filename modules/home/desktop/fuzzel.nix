{
  osConfig,
  lib,
  ...
}: {
  programs.fuzzel = lib.mkIf osConfig.desktop.enable {
    enable = true;
    settings.main = {
      terminal = "ghostty";
    };
  };
}
