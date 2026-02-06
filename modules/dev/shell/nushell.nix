{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.dev.shell.enable {
    home.packages = [ pkgs.moreutils ]; # vipe, chronic, pee
    programs.nushell = {
      enable = true;
      shellAliases = {
        k = "kubectl";
        fg = "job unfreeze";
        nn = "run-external $env.EDITOR ($env.HOME)/notes";
      };
      configFile.text = ''
        $env.config = {show_banner: false}

        source-env (if ("~/.profile.nu" | path exists) { "~/.profile.nu" } else null)

        def log [] {
          let now = date now
          let log_dir = $"($env.HOME)/notes/logs/($now | format date "%Y/%m")"

          if not ($log_dir | path exists) { mkdir $log_dir }

          cd $log_dir

          run-external $env.EDITOR $"($now | format date "%d").md"

          job spawn {
            do {
              let msg = $"Log update: ($now | format date '%F %T')"

              if (jj log --no-graph -r $"@- & files\('logs')" | is-not-empty) {
                jj squash --ignore-immutable
                jj describe -r @- -m $msg

                # After squash, the valid commit is @- (the working copy becomes empty/new)
                jj bookmark set main -r @-
                jj git push -b main

                return
              } else {
                jj describe -m $msg
                jj bookmark set main -r @
                jj git push -b main
              }

              ${lib.getExe' pkgs.libnotify "notify-send"} "Log Synced" $"Updates pushed to git.\n($msg)"
            } | complete
          } | ignore
        }

        ${lib.getExe pkgs.pokego} -l french
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
  };
}
