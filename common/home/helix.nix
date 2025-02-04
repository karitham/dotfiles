{pkgs, ...}: {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    extraPackages = with pkgs; [
      biome
      gopls
      golangci-lint
      gotools
      golangci-lint-langserver
      rubocop
      rubyPackages.solargraph
      nixd
      marksman
      sql-formatter
      nodePackages.prettier
      nodePackages.typescript-language-server
      vscode-langservers-extracted
      yaml-language-server
    ];

    settings = {
      keys = let
        plusMenu = {
          o = ":pipe-to xargs xdg-open";
        };
      in {
        insert = {
          C-space = "completion";
        };
        normal = {
          C-A-c = ":clipboard-yank";
          "+" = plusMenu;
        };
        select = {
          "+" = plusMenu;
        };
      };

      editor = {
        bufferline = "multiple";
        color-modes = true;
        auto-format = true;
        auto-save = true;
        lsp = {
          snippets = true;
          display-inlay-hints = true;
          display-messages = true;
        };
        soft-wrap = {
          enable = true;
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
          skip-levels = 1;
        };
      };
    };

    languages = {
      language-server.biome = {
        command = "biome";
        args = ["lsp-proxy"];
      };

      language = [
        {
          name = "nix";
          formatter = {
            command = "alejandra";
          };
          auto-format = true;
        }
        {
          name = "go";
          language-servers = ["gopls" "golangci-lint-lsp"];
          formatter = {
            command = "goimports";
          };
          auto-format = true;
        }
        {
          name = "ruby";
          language-servers = ["solargraph" "scls" "rust-analyzer"];
          auto-format = true;
          formatter = {
            command = "rubocop";
            args = ["--stdin" "file.rb" "-a" "--stderr" "--fail-level" "fatal"];
          };
        }
        {
          name = "html";
          language-servers = ["vscode-html-language-server"];
          formatter = {
            command = "prettier";
            args = ["--stdin-filepath" "file.html"];
          };
          auto-format = true;
        }
        {
          name = "javascript";
          language-servers = [
            {
              name = "typescript-language-server";
              except-features = ["format"];
            }
            "biome"
            "gpt"
          ];
          auto-format = true;
        }
        {
          name = "json";
          language-servers = [
            {
              name = "vscode-json-language-server";
              except-features = ["format"];
            }
            "biome"
          ];
          formatter = {
            command = "biome";
            args = ["format" "--indent-style" "space" "--stdin-file-path" "file.json"];
          };
          auto-format = true;
        }
        {
          name = "jsonc";
          language-servers = [
            {
              name = "vscode-json-language-server";
              except-features = ["format"];
            }
            "biome"
          ];
          formatter = {
            command = "biome";
            args = ["format" "--indent-style" "space" "--stdin-file-path" "file.jsonc"];
          };
          file-types = ["jsonc" "hujson"];
          auto-format = true;
        }
        {
          name = "jsx";
          language-servers = [
            {
              name = "typescript-language-server";
              except-features = ["format"];
            }
            "biome"
          ];
          formatter = {
            command = "biome";
            args = ["format" "--indent-style" "space" "--stdin-file-path" "file.jsx"];
          };
          auto-format = true;
        }
        {
          name = "typescript";
          language-servers = [
            {
              name = "typescript-language-server";
              except-features = ["format"];
            }
            "biome"
            "gpt"
          ];
          formatter = {
            command = "biome";
            args = ["format" "--indent-style" "space" "--stdin-file-path" "file.ts"];
          };
          auto-format = true;
        }
        {
          name = "yaml";
          language-servers = ["yaml-language-server"];
          formatter = {
            command = "prettier";
            args = ["--stdin-filepath" "file.yaml"];
          };
          auto-format = true;
        }
        {
          name = "markdown";
          language-servers = ["marksman"];
          formatter = {
            command = "prettier";
            args = ["--stdin-filepath" "file.md"];
          };
          auto-format = true;
        }
        {
          name = "sql";
          formatter = {
            command = "sql-formatter";
            args = ["-l" "postgresql" "-c" "{\"keywordCase\": \"lower\", \"dataTypeCase\": \"lower\", \"functionCase\": \"lower\", \"expressionWidth\": 120, \"tabWidth\": 4}"];
          };
          auto-format = true;
        }
      ];
    };
  };
}
