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
      lsp-ai
      typos-lsp
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
      language-server = {
        biome = {
          command = "biome";
          args = ["lsp-proxy"];
        };
        typos = {
          command = "typos-lsp";
          config = {
            diagnosticSeverity = "Warning";
            # config = ./typos.toml;
          };
        };
        lsp-ai = {
          command = "lsp-ai";
          config = {
            memory.file_store = {};
            models = {
              main = {
                type = "anthropic";
                chat_endpoint = "https://api.anthropic.com/v1/messages";
                model = "claude-3-5-sonnet-latest";
                auth_token_env_var_name = "ANTHROPIC_API_KEY";
              };
              fast = {
                type = "anthropic";
                chat_endpoint = "https://api.anthropic.com/v1/messages";
                model = "claude-3-5-haiku-latest";
                auth_token_env_var_name = "ANTHROPIC_API_KEY";
              };
            };
            completion = {
              model = "fast";
              parameters = {
                max_tokens = 128;
                max_context = 4096;
              };
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
                  max_context = 4096;
                  system = "You are a code assistant chatbot. The user will ask you for assistance coding and you will do you best to answer succinctly and accurately given the code context:\n\n{CONTEXT}";
                };
              }
            ];
            actions = [
              {
                action_display_name = "Refactor";
                model = "main";
                parameters = {
                  max_context = 4096;
                  max_tokens = 4096;
                  system = ''
                    You are an AI coding assistant specializing in code refactoring. Your task is to analyze the given code snippet and provide a refactored version. Follow these steps:

                    1. Analyze the code context and structure.
                    2. Identify areas for improvement, such as code efficiency, readability, or adherence to best practices.
                    3. Provide your chain of thought reasoning, wrapped in <reasoning> tags. Include your analysis of the current code and explain your refactoring decisions.
                    4. Rewrite the entire code snippet with your refactoring applied.
                    5. Wrap your refactored code solution in <answer> tags.

                    Your response should always include both the reasoning and the refactored code.

                    <examples>
                    <example>
                    User input:
                    def calculate_total(items):
                        total = 0
                        for item in items:
                            total = total + item['price'] * item['quantity']
                        return total


                    Response:
                    <reasoning>
                    1. The function calculates the total cost of items based on price and quantity.
                    2. We can improve readability and efficiency by:
                       a. Using a more descriptive variable name for the total.
                       b. Utilizing the sum() function with a generator expression.
                       c. Using augmented assignment (+=) if we keep the for loop.
                    3. We'll implement the sum() function approach for conciseness.
                    4. We'll add a type hint for better code documentation.
                    </reasoning>
                    <answer>
                    from typing import List, Dict

                    def calculate_total(items: List[Dict[str, float]]) -> float:
                        return sum(item['price'] * item['quantity'] for item in items)
                    </answer>
                    </example>

                    <example>
                    User input:
                    def is_prime(n):
                        if n < 2:
                            return False
                        for i in range(2, n):
                            if n % i == 0:
                                return False
                        return True


                    Response:
                    <reasoning>
                    1. This function checks if a number is prime, but it's not efficient for large numbers.
                    2. We can improve it by:
                       a. Adding an early return for 2, the only even prime number.
                       b. Checking only odd numbers up to the square root of n.
                       c. Using a more efficient range (start at 3, step by 2).
                    3. We'll also add a type hint for better documentation.
                    4. The refactored version will be more efficient for larger numbers.
                    </reasoning>
                    <answer>
                    import math

                    def is_prime(n: int) -> bool:
                        if n < 2:
                            return False
                        if n == 2:
                            return True
                        if n % 2 == 0:
                            return False

                        for i in range(3, int(math.sqrt(n)) + 1, 2):
                            if n % i == 0:
                                return False
                        return True
                    </answer>
                    </example>
                    </examples>
                  '';
                  messages = [
                    {
                      role = "user";
                      content = "{SELECTED_TEXT}";
                    }
                  ];
                };
                post_process = {
                  extractor = "(?s)<answer>(.*?)</answer>";
                };
              }
              {
                action_display_name = "Refactor 2";
                model = "main";
                parameters = {
                  max_context = 8192;
                  max_tokens = 4096;
                  messages = [
                    {
                      role = "user";
                      content = ''
                        You are an AI coding assistant specializing in code refactoring. Your task is to analyze and improve the given code snippet. Here's the code you need to refactor:

                        <code_snippet>
                        {SELECTED_TEXT}
                        </code_snippet>

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

      language = [
        {
          name = "nix";
          language-servers = ["nixd" "lsp-ai" "typos"];
          formatter = {
            command = "alejandra";
          };
          auto-format = true;
        }
        {
          name = "go";
          language-servers = ["gopls" "golangci-lint-lsp" "lsp-ai" "typos"];
          formatter = {
            command = "goimports";
          };
          auto-format = true;
        }
        {
          name = "ruby";
          language-servers = ["solargraph" "lsp-ai"];
          auto-format = true;
          formatter = {
            command = "rubocop";
            args = ["--stdin" "file.rb" "-a" "--stderr" "--fail-level" "fatal"];
          };
        }
        {
          name = "html";
          language-servers = ["vscode-html-language-server" "lsp-ai" "typos"];
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
            "lsp-ai"
            "typos"
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
            "typos"
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
            "lsp-ai"
            "typos"
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
          language-servers = ["marksman" "lsp-ai" "typos"];
          formatter = {
            command = "prettier";
            args = ["--stdin-filepath" "file.md"];
          };
          auto-format = true;
        }
        {
          name = "sql";
          language-servers = ["lsp-ai" "typos"];
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
