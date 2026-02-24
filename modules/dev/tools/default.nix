{
  config,
  lib,
  pkgs,
  ...
}:
let
  scripts = lib.pipe ./scripts [
    builtins.readDir
    (lib.mapAttrsToList (
      name: type: {
        name = "bin/${lib.removeSuffix ".nu" name}";
        path = ./scripts + "/${name}";
      }
    ))
    (pkgs.linkFarm "dev-tools-scripts")
  ];
in
{
  config = lib.mkIf config.dev.tools.enable {
    home.packages = [
      pkgs.sd
      pkgs.fd
      pkgs.uutils-coreutils-noprefix
      scripts
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

  imports = [ ./direnv.nix ];
}
