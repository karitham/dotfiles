{
  osConfig ? { },
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  config.dev = {
    inherit (osConfig.dev or { })
      shell
      editor
      vcs
      tools
      opencode
      ;
  };

  options.dev = {
    enable = mkEnableOption "all development tools";

    shell.enable = mkEnableOption "shell-related tools";
    editor.enable = mkEnableOption "editor tools";
    vcs.enable = mkEnableOption "version control tools";
    tools.enable = mkEnableOption "development utilities";
  };
  imports = [
    ./shell
    ./editor
    ./vcs
    ./tools
    ../opencode/home.nix
  ];
}
