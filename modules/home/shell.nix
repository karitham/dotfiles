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
      };
      configFile.text = ''
        $env.config = {
          show_banner: false,
          edit_mode: 'vi',
        }

        if ("~/.profile.nu" | path exists) {
          source-env "~/.profile.nu"
        }

        source ${./navi.plugin.nu}
        ${lib.meta.getExe pkgs.pokego} -l french
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
