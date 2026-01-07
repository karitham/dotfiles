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
  options.dev = {
    enable = mkEnableOption "all development tools";

    shell.enable = mkEnableOption "shell-related tools";
    editor.enable = mkEnableOption "editor tools";
    vcs.enable = mkEnableOption "version control tools";
    tools.enable = mkEnableOption "development utilities";
    docker.enable = mkEnableOption "Docker";
  };

  config = {
    dev.shell.enable = mkIf cfg.enable true;
    dev.editor.enable = mkIf cfg.enable true;
    dev.vcs.enable = mkIf cfg.enable true;
    dev.tools.enable = mkIf cfg.enable true;
    dev.docker.enable = mkIf cfg.enable true;

    users.defaultUserShell = mkIf (cfg.enable || cfg.shell.enable) pkgs.nushell;
    environment.shells = mkIf (cfg.enable || cfg.shell.enable) [ pkgs.nushell ];

    programs.nano.enable = mkDefault (!(cfg.enable || cfg.editor.enable));
    environment.sessionVariables.EDITOR = mkIf cfg.editor.enable "hx";
  };

  imports = [ ./docker ];
}
