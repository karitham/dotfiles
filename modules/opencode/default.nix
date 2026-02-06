{
  config,
  lib,
  pkgs,
  ...
}:
let
  rulesDir = ./rules;

  opencodePkg = pkgs.symlinkJoin {
    name = "opencode.wrapped";
    paths = [ pkgs.opencode ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/opencode \
        --set SHELL ${lib.getExe pkgs.bash} \
        --set-default LANGRULES_DIR ${rulesDir}
    '';
  };

  cfg = config.dev.opencode;
in
lib.mkIf cfg.enable {
  xdg.configFile."opencode/agents" = {
    source = ./agents;
    recursive = true;
  };

  xdg.configFile."opencode/AGENTS.md".source = ./AGENTS.md;

  programs.opencode = {
    enable = true;
    package = opencodePkg;
    enableMcpIntegration = cfg.enableMcp;
    settings = {
      theme = cfg.theme;
      plugin = [ "git@tangled.org:karitham.dev/langrules-opencode" ];
      permission = {
        todoread = "deny";
        todowrite = "deny";
      };
      mcp = lib.mkIf cfg.enableMcp {
        gopls = {
          type = "local";
          enabled = true;
          command = [
            "gopls"
            "mcp"
          ];
        };
      };
    };
  };

  programs.git.ignores = lib.mkIf cfg.enableLangRules [ ".rules" ];
  programs.helix.ignores = lib.mkIf cfg.enableLangRules [ "!.rules" ];
}
