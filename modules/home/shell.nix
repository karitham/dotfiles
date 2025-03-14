{
  pkgs,
  lib,
  ...
}: {
  home.packages = [
    pkgs.sd
    pkgs.coreutils
    pkgs.moreutils
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
        }

        if ("~/.profile.nu" | path exists) {
          source-env "~/.profile.nu"
        }

        source ${./navi.plugin.nu}
        ${lib.meta.getExe (pkgs.callPackage ../../pkgs/pokego.nix {})} -l french
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
