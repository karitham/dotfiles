{
  config,
  lib,
  ...
}: let
  aliases = {
    gs = "git status";
    nixupdate = "sudo nixos-rebuild switch --accept-flake-config --flake";
    k = "kubectl";
  };
in {
  config.programs = {
    zsh = lib.mkIf (config.shell.name == "zsh") {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = aliases;
    };
    nushell = lib.mkIf (config.shell.name == "nu") {
      enable = true;
      shellAliases = aliases;
      configFile.text = ''
        $env.config = {
          show_banner: false,
        }

        if ("~/.profile.nu" | path exists) {
          source-env "~/.profile.nu"
        }

        source ${./navi.plugin.nu}
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

    atuin.enable = true;
    atuin.flags = [
      "--disable-up-arrow"
    ];
    atuin.settings = {
      enter_accept = false;
      style = "compact";
    };

    starship.enable = true;
    # starship.settings.kubernetes.disabled = false;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      stdlib = ''
        alias() {
          mkdir -p .direnv/bin
          echo "#!/usr/bin/env sh
          $(which $2) \$@" >.direnv/bin/$1
          chmod +x .direnv/bin/$1
        }
        use_wg() {
          if [[ $1 ]] ; then
            wg-quick up $1
          else
            wg-quick up ./*.conf
          fi
        }
      '';
    };
  };
}
