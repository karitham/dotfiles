{ config, lib, ... }:
let
  cfg = config.dev;
  inherit (lib) mkEnableOption mkIf;

  sharedOptions = {
    enable = mkEnableOption "all development tools";
    shell.enable = mkEnableOption "shell-related tools";
    editor.enable = mkEnableOption "editor tools";
    vcs.enable = mkEnableOption "version control tools";
    tools.enable = mkEnableOption "development utilities";
  };
in
{
  options.dev = sharedOptions // {
    opencode.enable = mkEnableOption "OpenCode";
  };

  config = {
    dev.shell.enable = mkIf cfg.enable true;
    dev.editor.enable = mkIf cfg.enable true;
    dev.vcs.enable = mkIf cfg.enable true;
    dev.tools.enable = mkIf cfg.enable true;
    dev.opencode.enable = mkIf cfg.enable true;

    home-manager.sharedModules = [
      {
        options.dev = sharedOptions;
        config.dev = {
          enable = cfg.enable;
          shell.enable = cfg.shell.enable;
          editor.enable = cfg.editor.enable;
          vcs.enable = cfg.vcs.enable;
          tools.enable = cfg.tools.enable;
          opencode.enable = cfg.opencode.enable;
        };
      }
    ];
  };
}
