{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dev;
  inherit (lib) mkIf mkEnableOption mkDefault;
in
{
  imports = [ ./docker ];

  options.dev.enable = mkEnableOption "development tools";

  config = {
    users.defaultUserShell = mkIf cfg.enable pkgs.nushell;
    environment.shells = mkIf cfg.enable [ pkgs.nushell ];

    programs.nano.enable = mkDefault (!cfg.enable);
    environment.sessionVariables.EDITOR = mkIf cfg.enable "hx";
  };
}
