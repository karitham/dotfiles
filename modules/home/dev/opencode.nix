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
          command = ["gopls" "mcp"];
          enabled = true;
        };
      };
    };
  };
}
