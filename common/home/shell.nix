{
  pkgs,
  config,
  lib,
  ...
}: {
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
        gp = "git push";
        gc = "git commit";
        ga = "git add";
        nixupdate = "sudo nixos-rebuild switch --accept-flake-config --flake";
        k = "kubectl";
        kall = "kubectl get (kubectl api-resources --namespaced=true --no-headers -o name | split row --regex '\\s+' | where $it not-in ['node', 'events'] | str join ',') --no-headers";
      };
      configFile.text = ''
        $env.config = {
          show_banner: false,
        }

        def "from logfmt" [] {
          parse --regex '(?<key>\w+)\s?=\s?(?<value>"(?:[^(\\")]*)"|(?:[^\s]*))\s*' | transpose -r
        }

        def "decode secret" [] {
          update data {$in | transpose k v | each { {$in.k: ($in.v | decode base64 | decode)} | transpose -d} | transpose -r | get 0}
        }
        
        source ${./navi.plugin.nu}
      '';
    };
    zoxide.enable = true;
    carapace.enable = true;
    navi.enable = true;
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
