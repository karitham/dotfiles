{ config, lib, ... }: {
  options.dev = {
    enable = lib.mkEnableOption "development tools";
    shell.enable = lib.mkEnableOption "shell tools";
    editor.enable = lib.mkEnableOption "editor tools";
    vcs.enable = lib.mkEnableOption "version control tools";
    tools.enable = lib.mkEnableOption "dev utilities";
    # opencode.* options are defined in ../opencode/home.nix
  };

  config = {
    dev.shell.enable = lib.mkIf config.dev.enable true;
    dev.editor.enable = lib.mkIf config.dev.enable true;
    dev.vcs.enable = lib.mkIf config.dev.enable true;
    dev.tools.enable = lib.mkIf config.dev.enable true;
    # dev.opencode.enable is declared in ../opencode/home.nix
    dev.opencode.enable = lib.mkIf config.dev.enable true;
  };

  imports = [
    ./shell
    ./editor
    ./vcs
    ./tools
    ../opencode/home.nix
  ];
}
