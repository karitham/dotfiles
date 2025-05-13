{
  pkgs,
  inputs',
  ...
}: let
  global-tools = with pkgs; [
    alejandra
    biome
    golangci-lint
    gotools
    sql-formatter
    rubocop
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
        gopls
        golangci-lint-langserver
        rubyPackages.ruby-lsp
        nixd
        marksman
        nodePackages.typescript-language-server
        vscode-langservers-extracted
        yaml-language-server
        lsp-ai
        typos-lsp
      ]
      ++ global-tools;

    ignores = [
      ".zig-cache"
      "node_modules"
      ".direnv"
    ];

    settings = {
      keys = let
        plusMenu = {
          g = ":sh gh browse -n %{buffer_name}:%{cursor_line} | ${pkgs.wl-clipboard}/bin/wl-copy";
          b = ":echo %sh{git blame -L %{cursor_line},+1 %{buffer_name}}";
        };
        runMenu = {
          t = ":sh nu -c 'go test (\"%{buffer_name}\" | path dirname | path expand)'";
          f = [":sh golangci-lint run --issues-exit-code=0 --fix %{buffer_name}" ":reload"];
        };
      in {
        insert = {
          C-space = "completion";
        };
        normal = {
          C-A-c = ":clipboard-yank";
          "+" = plusMenu;
          "-" = runMenu;
        };
        select = {
          C-A-c = ":clipboard-yank";
          "+" = plusMenu;
          "-" = runMenu;
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
          "diff"
          "diagnostics"
        ];
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
      language-server = {
        biome = {
          command = "biome";
          args = ["lsp-proxy"];
        };
        typos = {
          command = "typos-lsp";
          config = {
            diagnosticSeverity = "Warning";
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
        };
        golangci-lint-lsp = {
          command = "golangci-lint-langserver";
          config = {
            command = [
              "golangci-lint"
              "run"
              "--output.json.path"
              "stdout"
              "--path-mode=abs"
              "--show-stats=false"
              "--issues-exit-code=1"
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

        lsp-ai = {
          command = "lsp-ai";
          timeout = 60;
          config = {
            memory.file_store = {};
            models = rec {
              claude-sonnet = {
                type = "anthropic";
                chat_endpoint = "https://api.anthropic.com/v1/messages";
                model = "claude-3-5-sonnet-latest";
                auth_token_env_var_name = "ANTHROPIC_API_KEY";
              };
              main = claude-sonnet;
            };
            chat = [
              {
                trigger = "!C";
                action_display_name = "Chat";
                model = "main";
                parameters = {
                  max_tokens = 1024;
                  max_context = 4096;
                  system = "You are a code assistant chatbot. The user will ask you for assistance coding and you will do you best to answer succinctly and accurately";
                };
              }
              {
                trigger = "!CC";
                action_display_name = "Chat with context";
                model = "main";
                parameters = {
                  max_tokens = 1024;
                  max_context = 8192;
                  system = "You are a code assistant chatbot. The user will ask you for assistance coding and you will do you best to answer succinctly and accurately given the code context:\n\n{CONTEXT}";
                };
              }
            ];
            actions = [
              {
                action_display_name = "Refactor";
                model = "claude-sonnet";
                parameters = {
                  max_context = 8192;
                  max_tokens = 4096;
                  system = ''
                    You are an AI coding assistant specializing in code refactoring. Your task is to analyze and improve the given code snippet.

                    Please follow these steps to refactor the code:

                    1. Analyze the code context and structure.
                    2. Identify areas for improvement, focusing on:
                       - Code efficiency
                       - Readability
                       - Adherence to Python best practices and idioms
                       - Correctness of conventions

                    3. Wrap your analysis in <refactoring_analysis> tags. In this analysis:
                       - List specific areas for improvement under each category (efficiency, readability, best practices, conventions)
                       - Briefly explain your refactoring decisions, focusing on:
                         - What improvements you're making
                         - Why these changes enhance the code
                         - Any trade-offs involved in the proposed changes

                    4. Rewrite the entire code snippet with your refactoring applied. When refactoring:
                       - Prioritize simplicity and readability
                       - Use correct conventions and idioms
                       - Be explicit in your code
                       - Do not add comments that explain the code

                    5. Present your refactored code solution in <answer> tags.

                    Remember:
                    - Only include code in the <answer> section.
                    - Do not add explanatory comments within the code itself.
                    - Ensure the refactored code is simple to read and understand.

                    Your response should always include both the refactoring analysis and the refactored code, in that order.

                    Here is example output:

                    <refactoring_analysis>
                    [Your analysis about the steps taken for the refactoring]
                    </refactoring_analysis>

                    <answer>
                    [The newly refactored code]
                    </answer>
                  '';
                  messages = [
                    {
                      role = "user";
                      content = ''
                        Here's the code you need to refactor:

                        <code_snippet>
                        {SELECTED_TEXT}
                        </code_snippet>
                      '';
                    }
                  ];
                };
                post_process = {
                  extractor = "(?s)<answer>(.*?)</answer>";
                };
              }
            ];
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
                then
                  lang.language-servers
                  ++ defaults
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
              language-servers = ["ruby-lsp" "rubocop"];
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
                  "--indent-style"
                  "space"
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
                  "--indent-style"
                  "space"
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
                  "--indent-style"
                  "space"
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
                  "--indent-style"
                  "space"
                  "--stdin-file-path"
                  "file.jsx"
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
                  "--indent-style"
                  "space"
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
              language-servers = ["marksman"];
              text-width = 100;
              rulers = [100];
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
                  "-l"
                  "postgresql"
                  "-c"
                  ''
                    {
                      "keywordCase": "upper",
                      "dataTypeCase": "upper",
                      "functionCase": "upper",
                      "expressionWidth": 120,
                      "tabWidth": 4
                    }''
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
