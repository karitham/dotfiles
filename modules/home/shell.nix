{
  pkgs,
  lib,
  ...
}: {
  home.packages = [
    pkgs.sd
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
        # ${lib.meta.getExe pkgs.pokego} -l french
      '';

      extraLogin = ''
        bash -c ". /etc/profile && env"
         | parse "{n}={v}"
         | filter { |x| ($x.n not-in $env) or $x.v != ($env | get $x.n) }
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

    starship.enable = true;
    # starship.settings.kubernetes.disabled = false;

    less.enable = true;
    less.keys = ''
      #env
      LESS = -S -R -i
    '';
  };
}
