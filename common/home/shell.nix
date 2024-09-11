{
  pkgs,
  config,
  lib,
  ...
}: let
  nuPluginQuery = pkgs.callPackage ./nu_plugin_query.nix {};
in {
  config.home.packages = lib.mkIf (config.shell.name == "nu") [nuPluginQuery];

  config.programs = {
    zsh = lib.mkIf (config.shell.name == "zsh") {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        gs = "git status";
        ls = "eza --git";
        nixupdate = "sudo nixos-rebuild switch --accept-flake-config --flake";
        k = "kubectl";
        kall = "kubectl get $(kubectl api-resources --namespaced=true --no-headers -o name | egrep -v 'events|nodes' | paste -s -d, - ) --no-headers";
      };
    };
    nushell = lib.mkIf (config.shell.name == "nu") {
      enable = true;
      shellAliases = {
        gs = "git status";
        nixupdate = "sudo nixos-rebuild switch --accept-flake-config --flake";
        k = "kubectl";
        kall = "kubectl get (kubectl api-resources --namespaced=true --no-headers -o name | split row --regex '\s+' | where $it not-in ['node', 'events'] | str join ',') --no-headers";
      };
      configFile.text = lib.concatStrings [
        ''
          $env.config = {
            show_banner: false,
          }
        ''
        (lib.concatStrings (map (plugin: "plugin add ${plugin}\n") [
          "${nuPluginQuery}/bin/nu_plugin_query"
        ]))
      ];
    };
    zoxide.enable = true;

    atuin.enable = true;
    atuin.flags = [
      "--disable-up-arrow"
    ];
    atuin.settings = {
      enter_accept = false;
      style = "compact";
    };

    starship.enable = true;
    starship.settings.kubernetes.disabled = false;

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
