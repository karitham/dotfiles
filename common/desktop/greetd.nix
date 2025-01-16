{pkgs, ...}: {
  services.greetd = {
    enable = true;
    vt = 7; # # tty to skip startup msgs
    settings = {
      default_session.command = ''
        ${pkgs.greetd.tuigreet}/bin/tuigreet \
          --time \
          --asterisks \
          --user-menu \
          --cmd Hyprland
      '';
    };
  };

  environment.etc."greetd/environments".text = ''
    hyprland
  '';
}
