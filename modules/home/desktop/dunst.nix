{
  osConfig,
  lib,
  ...
}: {
  services.dunst = lib.mkIf osConfig.desktop.enable {
    enable = true;
  };
}
