{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.dev.enable {
    home.packages = [ pkgs.moreutils ]; # vipe, chronic, pee
    programs.nushell = {
      enable = true;
      # stateVersion is 26.05, so the 26.11 default does not apply.
      loadSessionVariables = true;
      shellAliases = {
        k = "kubectl";
        fg = "job unfreeze";
        nn = "run-external $env.EDITOR ($env.HOME)/notes";
      };
      configFile.text = ''
        $env.config = {show_banner: false, edit_mode: helix}

        source-env (if ("~/.profile.nu" | path exists) { "~/.profile.nu" } else null)
      '';
    };
  };
}
