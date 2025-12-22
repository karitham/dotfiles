{pkgs, ...}: {
  programs.opencode = let
    opencodePkg = pkgs.symlinkJoin {
      name = "opencode-wrapped";
      paths = [pkgs.opencode];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/opencode \
          --set SHELL ${pkgs.bash}/bin/bash
      '';
    };
  in {
    enable = true;
    package = opencodePkg;
    enableMcpIntegration = true;
    settings = {
      theme = "catppuccin-macchiato";
      agent = {
        stack-analyst = {
          description = "Analyzes stack traces to map errors to code paths and identify root causes";
          prompt = builtins.readFile ./opencode/stack-analyst.md;
          mode = "primary";
          tools = {
            read = true;
            glob = true;
            grep = true;
            write = true;
            edit = false;
            bash = true;
          };
          permissions = {
            bash = {
              "git status" = "allow";
              "git log" = "allow";
              "*" = "ask";
            };
          };
        };
      };
      mcp = {
        linear = {
          type = "remote";
          url = "https://mcp.linear.app/mcp";
          enabled = true;
          headers = {
            Authorization = "Bearer {env:LINEAR_API_KEY}";
          };
        };
        gopls = {
          type = "local";
          enabled = true;
          command = ["gopls" "mcp"];
        };
        sentry = {
          type = "local";
          enabled = true;
          command = ["${pkgs.bun}/bin/bun" "x" "mcp-remote@latest" "https://mcp.sentry.dev/mcp"];
        };
      };
    };
  };
}
