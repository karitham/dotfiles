{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  config = lib.mkIf config.desktop.enable {
    environment.systemPackages = [
      inputs.zen-browser.packages."${pkgs.system}".default
    ];
  };
}
