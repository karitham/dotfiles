{
  lib,
  pkgs,
  ...
}: {
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

      if ("~/.profile.nu" | path exists) {
        source-env "~/.profile.nu"
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
}
