{pkgs, ...}: {
  home.packages = with pkgs; [
    gopls
    rubocop
    nixd
    marksman
  ];
  programs.helix = {
    enable = true;
    defaultEditor = true;

    languages = {
      language = [
        {
          name = "nix";
          formatter.command = "alejandra";
          language-servers = ["nixd" "nil"];
          auto-format = true;
        }
        {
          name = "go";
          formatter.command = "goimports";
        }
        {
          name = "ruby";
          language-servers = ["solargraph" "scls" "rust-analyzer"];
          auto-format = true;
          formatter = {
            command = "rubocop";
            args = ["--stdin" "foo.rb" "-a" "--stderr" "--fail-level" "fatal"];
          };
        }
      ];

      language-server.nixd = {
        command = "nixd";
      };
    };

    settings = {
      keys = {
        normal = {
          C-A-c = ":clipboard-yank";
        };
      };
      editor = {
        completion-trigger-len = 1;
        bufferline = "multiple";
        color-modes = true;
        auto-format = true;
        auto-save = true;
        lsp = {
          snippets = true;
        };
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
        end-of-line-diagnostics = "hint";
        inline-diagnostics = {
          cursor-line = "warning"; # show warnings and errors on the cursorline inline
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
