{
  lib,
  osConfig,
  ...
}: {
  config = lib.mkIf osConfig.desktop.enable {
    programs.vesktop.enable = true;
  };
}
