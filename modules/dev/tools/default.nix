{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.dev.tools.enable {
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
  };

  imports = [
    ./direnv.nix
    ./opencode.nix
  ];
}
