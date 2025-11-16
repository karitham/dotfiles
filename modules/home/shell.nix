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
    nushell = {
      enable = true;
      shellAliases = {
        k = "kubectl";
        fg = "job unfreeze";
      };
      configFile.text = ''
        $env.config = {
          show_banner: false,
        }

        if ("~/.profile.nu" | path exists) {
          source-env "~/.profile.nu"
        }

        source ${./navi.plugin.nu}
        ${lib.meta.getExe pkgs.pokego} -l french
      '';

      extraLogin = ''
        bash -c ". /etc/profile && env"
         | parse "{n}={v}"
         | where n not-in $env or v != ($env | get $it.n)
         | where n not-in ["_", "LAST_EXIT_CODE", "DIRS_POSITION"]
         | transpose --header-row
         | into record
         | load-env
      '';
    };
    zoxide.enable = true;
    carapace.enable = true;

    navi.enable = true;
    navi.settings = {
      cheats = {
        paths = [
          ./navi
          "~/.local/share/navi/cheats"
        ];
      };
    };

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
