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
  imports = [
    ../options/dev.nix
    ./docker
  ];

  options.dev = {
    docker.enable = mkEnableOption "Docker";
  };

  config = {
    dev.docker.enable = mkIf cfg.enable true;

    users.defaultUserShell = mkIf (cfg.enable || cfg.shell.enable) pkgs.nushell;
    environment.shells = mkIf (cfg.enable || cfg.shell.enable) [ pkgs.nushell ];

    programs.nano.enable = mkDefault (!(cfg.enable || cfg.editor.enable));
    environment.sessionVariables.EDITOR = mkIf cfg.editor.enable "hx";
  };
}
