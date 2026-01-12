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
        nn = "exec $env.EDITOR ~/notes";
      };
      configFile.text = ''
        $env.config = {
          show_banner: false,
        }

        source-env (if ("~/.profile.nu" | path exists) {"~/.profile.nu"} else null)

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
