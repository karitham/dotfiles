{
  lib,
  pkgs,
  inputs',
  ...
}: let
  global-tools = with pkgs; [
    alejandra
    biome
    golangci-lint
    gotools
    gopls
    sql-formatter
    nodePackages.prettier
  ];
in {
  home.packages = global-tools;
  programs.helix = {
    enable = true;
    defaultEditor = true;
    package = inputs'.helix.packages.default;
    extraPackages = with pkgs;
      [
        golangci-lint-langserver
        nixd
        marksman
        nodePackages.typescript-language-server
        vscode-langservers-extracted
        yaml-language-server
        typos-lsp
      ]
      ++ global-tools;

    ignores = [
      ".zig-cache"
      "node_modules"
      ".direnv"
      "!/notes"
    ];

    settings = {
      keys = let
        plusMenu = {
          g = ":sh gh browse -n %{buffer_name}:%{cursor_line} | ${pkgs.wl-clipboard}/bin/wl-copy";
          b = ":echo %sh{git blame -L %{cursor_line},+1 %{buffer_name}}";
        };
        goMenu = {
          "8" = ["move_prev_word_start" "move_next_word_end"];
          "c" = caseMenu;
        };
        caseMenu = {
          p = ":pipe ${lib.getExe pkgs.sttr} pascal";
          c = ":pipe ${lib.getExe pkgs.sttr} camel";
          k = ":pipe ${lib.getExe pkgs.sttr} kebab";
          K = ":pipe ${lib.getExe pkgs.sttr} kebab | ${lib.getExe pkgs.sttr} upper";
          s = ":pipe ${lib.getExe pkgs.sttr} snake";
          S = ":pipe ${lib.getExe pkgs.sttr} snake | ${lib.getExe pkgs.sttr} upper";
          t = ":pipe ${lib.getExe pkgs.sttr} title";
        };
        runMenu = {
          f = [
            ":sh golangci-lint run --issues-exit-code=0 --fix %{buffer_name}"
            ":reload"
          ];
        };
      in {
        normal = {
          "+" = plusMenu;
          "-" = runMenu;
          "g" = goMenu;
        };
        select = {
          "+" = plusMenu;
          "-" = runMenu;
          "." = goMenu;
        };
      };

      editor = {
        scrolloff = 10;
        text-width = 120;
        rulers = [120];
        bufferline = "multiple";
        color-modes = true;
        auto-format = true;
        auto-save = true;
        lsp = {
          snippets = true;
          display-color-swatches = true;
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
        gutters = [
          "line-numbers"
          "diagnostics"
          "diff"
        ];
        end-of-line-diagnostics = "hint";
        inline-diagnostics = {
          cursor-line = "warning"; # show warnings and errors on the cursorline inline
        };
        cursor-shape = {
          insert = "bar";
          normal = "bar";
          select = "underline";
        };
        whitespace.render.tab = "all";
        indent-guides = {
          render = true;
          character = "┊";
          skip-levels = 1;
        };
      };
    };

    languages = {
      language-server = {
        biome = {
          command = "biome";
          args = ["lsp-proxy"];
        };
        nu-lsp = {
          command = "nu";
          args = ["--lsp" "--no-config-file"];
        };
        typos = {
          command = "typos-lsp";
          config = {
            diagnosticSeverity = "Warning";
          };
        };
        yaml-language-server = {
          config = {
            enabled = true;
            enabledForFilesGlob = "*.{yaml,yml}";
            diagnosticsLimit = 50;
            showDiagnosticsDirectly = false;
            config = {
              schemas = {
                kubernetes = "templates/**";
              };
              completion = true;
              hover = true;
            };
          };
        };
        golangci-lint-lsp = {
          command = "golangci-lint-langserver";
          config = {
            command = [
              "nu"
              "-c"
              ''
                let args = [
                  --output.json.path=stdout
                  --path-mode=abs
                  --issues-exit-code=1
                  --show-stats=false
                ]

                if ($env.GOLANGCI_LINT_CONFIG? | is-not-empty) {
                  golangci-lint run --config $env.GOLANGCI_LINT_CONFIG ...$args
                } else {
                  golangci-lint run ...$args
                }
              ''
            ];
          };
        };
        rubocop = {
          command = "rubocop";
          args = ["--lsp"];
        };
        ruby-lsp = {
          command = "ruby-lsp";
          config = {
            diagnostics = true;
            formatting = true;
            config = {
              initializationOptions = {
                enabledFeatures = {
                  codeActions = true;
                  codeLens = true;
                  completion = true;
                  definition = true;
                  diagnostics = true;
                  documentHighlights = true;
                  documentLink = true;
                  documentSymbols = true;
                  foldingRanges = true;
                  formatting = true;
                  hover = true;
                  inlayHint = true;
                  onTypeFormatting = true;
                  selectionRanges = true;
                  semanticHighlighting = true;
                  signatureHelp = true;
                  typeHierarchy = true;
                  workspaceSymbol = true;
                };
                featuresConfiguration = {
                  inlayHint = {
                    implicitHashValue = true;
                    implicitRescue = true;
                  };
                };
              };
            };
          };
        };
      };

      language = let
        defaults = [
          "typos"
        ];
      in
        map
        (
          lang:
            lang
            // {
              language-servers =
                if lang ? language-servers
                then lang.language-servers ++ defaults
                else defaults;
            }
        )
        (
          [
            {
              name = "nix";
              language-servers = ["nixd"];
              formatter = {
                command = "alejandra";
              };
              auto-format = true;
            }
            {
              name = "go";
              language-servers = [
                "gopls"
                "golangci-lint-lsp"
              ];
              formatter = {
                command = "goimports";
              };
              auto-format = true;
            }
            {
              name = "ruby";
              language-servers = [
                "ruby-lsp"
                "rubocop"
              ];
              auto-format = true;
            }
            {
              name = "html";
              language-servers = ["vscode-html-language-server"];
              formatter = {
                command = "prettier";
                args = [
                  "--stdin-filepath"
                  "file.html"
                ];
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
                args = [
                  "format"
                  "--stdin-file-path"
                  "file.json"
                ];
              };
              auto-format = true;
            }
            {
              name = "graphql";
              formatter = {
                command = "biome";
                args = [
                  "format"
                  "--stdin-file-path"
                  "file.gql"
                ];
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
                args = [
                  "format"
                  "--stdin-file-path"
                  "file.jsonc"
                ];
              };
              file-types = [
                "jsonc"
                "hujson"
              ];
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
                args = [
                  "format"
                  "--stdin-file-path"
                  "file.jsx"
                ];
              };
              auto-format = true;
            }
            {
              name = "tsx";
              language-servers = [
                {
                  name = "typescript-language-server";
                  except-features = ["format"];
                }
                "biome"
              ];
              formatter = {
                command = "biome";
                args = [
                  "format"
                  "--stdin-file-path"
                  "file.tsx"
                ];
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
              ];
              formatter = {
                command = "biome";
                args = [
                  "format"
                  "--stdin-file-path"
                  "file.ts"
                ];
              };
              auto-format = true;
            }
            {
              name = "yaml";
              language-servers = ["yaml-language-server"];
              formatter = {
                command = "prettier";
                args = [
                  "--stdin-filepath"
                  "file.yaml"
                ];
              };
              auto-format = true;
            }
            {
              name = "helm";
              language-servers = ["helm_ls"];
            }
            {
              name = "typst";
              language-servers = ["tinymist"];
            }
            {
              name = "markdown";
              language-servers = [
                "marksman"
                # "vale-ls"
              ];
              text-width = 100;
              rulers = [100];
              soft-wrap = {
                enable = true;
                wrap-at-text-width = true;
              };
              formatter = {
                command = "prettier";
                args = [
                  "--stdin-filepath"
                  "file.md"
                ];
              };
              auto-format = true;
            }
            {
              name = "sql";
              formatter = {
                command = "sql-formatter";
                args = [
                  "-c"
                  (builtins.toJSON {
                    keywordCase = "upper";
                    functionCase = "upper";
                    dataTypeCase = "upper";
                    identifierCase = "lower";
                    language = "postgresql";
                    expressionWidth = 80;
                    tabWidth = 2;
                  })
                ];
              };
              auto-format = false;
            }
            {
              name = "nu";
              language-servers = ["nu-lsp"];
              formatter = {
                command = "${lib.getExe pkgs.topiary-nu}";
                args = [
                  "format"
                  "--language"
                  "nu"
                ];
              };
              auto-format = true;
            }
          ]
          ++ map (lang: {name = lang;}) [
            "git-attributes"
            "git-commit"
            "git-config"
            "git-ignore"
            "git-rebase"
          ]
        );
    };
  };
}
