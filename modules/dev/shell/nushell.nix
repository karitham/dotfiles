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
              jj bookmark set main -r @
              jj describe -m $"Log update: ($now | format date '%F %T')"
              jj git push -b main
            } | complete
          } | ignore
        }

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
  };
}
