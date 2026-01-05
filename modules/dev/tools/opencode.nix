{
  config,
  lib,
  pkgs,
  ...
}:
let
  opencodePkg = pkgs.symlinkJoin {
    name = "opencode.wrapped";
    paths = [
      pkgs.opencode
      pkgs.nixd
    ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/opencode \
        --set SHELL ${lib.getExe pkgs.bash}
    '';
  };
in
{
  config = lib.mkIf config.dev.tools.enable {
    xdg.configFile."opencode/agent" = {
      source = ./opencode-agents;
      recursive = true;
    };

    programs.opencode = {
      enable = true;
      package = opencodePkg;
      enableMcpIntegration = true;
      settings = {
        theme = "catppuccin-macchiato";
        mcp = {
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
  };
}
