{...}: {
  programs.helix = {
    enable = true;
    defaultEditor = true;

    languages.auto-format = true;
    languages.language = [
      {
        name = "nix";
        formatter.command = "alejandra";
      }
    ];

    settings = {
      editor = {
        line-number = "relative";
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
