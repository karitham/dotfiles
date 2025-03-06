{
  pkgs,
  osConfig,
  lib,
  ...
}: let
  aliases = {
    gs = "git status";
    nixupdate = "sudo nixos-rebuild switch --accept-flake-config --flake";
    k = "kubectl";
  };
in {
  programs = {
    zsh = lib.mkIf (osConfig.shell.name == "zsh") {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = aliases;
    };
    nushell = lib.mkIf (osConfig.shell.name == "nu") {
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
