{ pkgs, ... }: {
  home.packages = [
    # youtube music in browser
    (pkgs.ytmdesktop.override { commandLineArgs = "--password-store=gnome-libsecret"; })
  ];
}
