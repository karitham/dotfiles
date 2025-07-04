_: {
  programs.nixvim = {
    enable = true;
    opts = {
      scrolloff = 10;
      textwidth = 120;
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      swapfile = false;
      undofile = true;
      incsearch = true;
      inccommand = "split";
      ignorecase = true;
      smartcase = true;
      signcolumn = "yes:1";
      updatetime = 100;
      list = true;
      listchars = "tab:┊ ";
      wrap = true;
      linebreak = true;
    };

    keymaps = [
      {
        action = "<cmd>LspInfo<CR>";
        key = "<leader>li";
        options.desc = "LSP Info";
      }
      {
        action = "<cmd>Oil<CR>";
        key = "<leader>-";
      }
      {
        action = "<cmd>Telescope find_files<CR>";
        key = "<leader>ff";
      }
      {
        action = "<cmd>Telescope live_grep<CR>";
        key = "<leader>fg";
      }
      {
        action = "<cmd>Telescope buffers<CR>";
        key = "<leader>fb";
      }
      {
        action = "<cmd>Telescope help_tags<CR>";
        key = "<leader>fh";
      }
    ];

    globals = {
      mapleader = " ";
      direnv_auto = 1;
      direnv_silent_load = 0;
    };

    highlight.ExtraWhitespace.bg = "red";

    plugins = {
      lsp-format.enable = true;
      lsp = {
        enable = true;
        servers = {
          jsonls = {
            enable = true;
            settings = {
              json.format.enable = false;
            };
          };
          marksman.enable = true;
          nil_ls = {
            enable = true;
          };
          yamlls = {
            enable = true;
            settings = {
              yaml.schemas = {
                kubernetes = "templates/**";
              };
              yaml.completion = true;
              yaml.hover = true;
              yaml.diagnostics.limit = 50;
              yaml.editor.formatOnType = true;
            };
          };

          gopls.enable = true;
          golangci_lint_ls = {
            enable = true;
            settings = {
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
          ts_ls = {
            enable = true;
            settings = {
              javascript.format.enable = false;
              typescript.format.enable = false;
              jsx.format.enable = false;
              tsx.format.enable = false;
            };
          };
          biome = {
            enable = true;
            cmd = [
              "biome"
              "lsp-proxy"
            ];
            filetypes = [
              "javascript"
              "javascriptreact"
              "json"
              "jsonc"
              "typescript"
              "typescriptreact"
              "markdown"
              "html"
              "css"
              "graphql"
            ];
          };
          typos_lsp = {
            enable = true;
            cmd = ["typos-lsp"];
            settings = {
              diagnosticSeverity = "Warning";
            };
          };
          ruby_lsp = {
            enable = true;
            settings = {
              diagnostics = true;
              formatting = true;
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
          rubocop = {
            enable = true;
            cmd = [
              "rubocop"
              "--lsp"
            ];
          };
          helm_ls.enable = true;
        };
      };

      blink-cmp = {
        enable = true;
        setupLspCapabilities = true;
        settings = {
          appearance = {
            nerd_font_variant = "normal";
            use_nvim_cmp_as_default = true;
          };
          cmdline = {
            enabled = true;
            keymap = {
              preset = "inherit";
            };
            completion = {
              list.selection.preselect = false;
              menu = {
                auto_show = true;
              };
              ghost_text = {
                enabled = true;
              };
            };
          };
          completion = {
            menu.border = "rounded";
            accept = {
              auto_brackets = {
                enabled = true;
                semantic_token_resolution = {
                  enabled = false;
                };
              };
            };
            documentation = {
              auto_show = true;
              window.border = "rounded";
            };
          };
          sources = {
            default = [
              "lsp"
              "buffer"
              "path"
              "snippets"
              "git"
            ];
            providers = {
              buffer = {
                enabled = true;
                score_offset = 0;
              };
              lsp = {
                name = "LSP";
                enabled = true;
                score_offset = 10;
              };
              git = {
                module = "blink-cmp-git";
                name = "Git";
              };
            };
          };
        };
      };
      blink-cmp-git.enable = true;
      blink-compat.enable = true;
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            css = ["prettier"];
            html = ["prettier"];
            json = [
              "biome"
              "prettier"
            ];
            jsonc = ["biome"];
            javascript = ["biome"];
            javascriptreact = ["biome"];
            typescript = ["biome"];
            typescriptreact = ["biome"];
            graphql = ["biome"];
            lua = ["stylua"];
            markdown = ["prettier"];
            nix = ["alejandra"];
            go = ["goimports"];
            ruby = ["rubyfmt"];
            yaml = ["prettier"];
            sql = ["sql_formatter"];
          };
          formatters = {
            sql_formatter = {
              command = "sql-formatter";
              args = [
                "-l"
                "postgresql"
                "-c"
                ''{ "keywordCase": "upper", "dataTypeCase": "upper", "functionCase": "upper", "expressionWidth": 80, "tabWidth": 4 }''
              ];
            };
            prettier = {
              command = "prettier";
              args = [
                "--stdin-filepath"
                "$FILENAME"
              ];
            };
            biome = {
              command = "biome";
              args = [
                "format"
                "--stdin-file-path"
                "$FILENAME"
              ];
            };
          };
        };
      };
      lspkind.enable = true;
      dressing.enable = true;
      fugitive.enable = true;
      fzf-lua.enable = true;
      git-conflict.enable = true;
      lualine = {
        enable = true;
        settings = {
          sections = {
            lualine_a = ["mode"];
            lualine_b = [
              "diagnostics"
              "diff"
            ];
            lualine_c = [
              "filename"
              "branch"
            ];
            lualine_x = [
              "filetype"
              "encoding"
              "selectioncount"
            ];
            lualine_y = ["progress"];
            lualine_z = ["location"];
          };
          options = {
            theme = "auto";
            component_separators = "|";
            section_separators = {
              left = "";
              right = "";
            };
            globalstatus = true;
          };
        };
      };
      luasnip.enable = false;
      none-ls.sources.formatting.black.enable = true;
      oil.enable = true;
      telescope.enable = true;
      treesitter = {
        enable = true;
        folding = false;
        settings.indent.enable = true;
      };
      web-devicons.enable = true;
      which-key = {
        enable = true;
        settings.preset = "helix";
      };
    };
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    colorschemes.catppuccin = {
      settings.flavour = "macchiato";
      enable = true;
    };

    autoCmd = [
      {
        event = ["BufWritePre"];
        command = "silent! lua vim.lsp.buf.format({ async = true })";
      }
    ];
  };
}
