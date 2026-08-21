{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.desktop.enable {
    home.packages = [
      # youtube music in browser
      (pkgs.ytmdesktop.override { commandLineArgs = "--password-store=gnome-libsecret"; })
    ];
  };
}
