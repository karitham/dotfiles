{...}: {
  programs.helix = {
    enable = true;
    defaultEditor = true;

    languages = {
      auto-format = true;
      language = [
        {
          name = "nix";
          formatter.command = "alejandra";
          language-servers = ["nixd" "nil"];
        }
        {
          name = "go";
          formatter.command = "goimports";
        }
      ];
      
      language-server.nixd = {
        command = "nixd";
      };
    };

    settings = {
      editor = {
        completion-trigger-len = 1;
        bufferline = "multiple";
        color-modes = true;
        statusline = {
          left = [
            "mode"
            "spacer"
            "diagnostics"
            "version-control"
            "file-name"
            "read-only-indicator"
            "file-modification-indicator"
            "spinner"
          ];
          right = [
            "file-encoding"
            "file-type"
            "selections"
            "position"
          ];
        };
        cursor-shape.insert = "bar";
        whitespace.render.tab = "all";
        indent-guides = {
          render = true;
          character = "┊";
        };
      };
    };
  };
}
