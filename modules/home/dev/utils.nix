{
  pkgs,
  lib,
  ...
}: {
  home.packages = [
    pkgs.sd
    pkgs.fd
    pkgs.uutils-coreutils-noprefix
  ];
  programs = {
    zoxide.enable = true;
    carapace.enable = true;

    ripgrep.enable = true;
    bat.enable = true;
    less = {
      enable = true;
      config = ''
        #env
        LESS = -S -R -i
      '';
    };
  };
}
