{
  config,
  lib,
  pkgs,
  self',
  ...
}:
let
  opencodePkg = pkgs.symlinkJoin {
    name = "opencode-wrapped";
    paths = [ pkgs.opencode ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/opencode \
        --set OPENCODE_EXPERIMENTAL_LSP_TOOL true \
        --set OPENCODE_DISABLE_LSP_DOWNLOAD true \
        --set OPENCODE_DISABLE_AUTOUPDATE true \
        --set OPENCODE_EXPERIMENTAL_MARKDOWN true \
        --set SHELL "${lib.getExe pkgs.bash}" \
        --prefix PATH : "${
          lib.makeBinPath [
            pkgs.golangci-lint-langserver
            pkgs.nixd
            pkgs.marksman
            pkgs.typescript-language-server
            pkgs.vscode-langservers-extracted
            pkgs.yaml-language-server
            pkgs.typos-lsp
            pkgs.nil
          ]
        }"
    '';
  };

  cfg = config.dev.opencode;
in
lib.mkIf cfg.enable {
  home.packages = [ self'.packages.strands-agents-sops ];

  xdg.configFile."opencode/agents" = {
    source = ./agents;
    recursive = true;
  };

  xdg.configFile."opencode/skills" = {
    source = pkgs.symlinkJoin {
      name = "opencode-skills";
      paths = [
        self'.packages.strands-sops-skills
        ./skills
      ];
    };
    recursive = true;
  };

  xdg.configFile."opencode/commands" = {
    source = pkgs.symlinkJoin {
      name = "opencode-commands";
      paths = [ ./commands ];
    };
    recursive = true;
  };

  xdg.configFile."opencode/AGENTS.md".source = ./AGENTS.md;

  # Notifier config omitted — plugin uses all defaults.
  # If customization is needed, add xdg.configFile."opencode/opencode-notifier.json".text = builtins.toJSON { ... };

  programs.opencode = {
    enable = true;
    package = opencodePkg;
    enableMcpIntegration = cfg.enableMcp;
    settings = {
      plugin = [ "@mohak34/opencode-notifier@0.2.2" ];
      experimental = {
        batch_tool = true;
      };
      inherit (cfg) theme;
      default_agent = "ask";
      formatter = {
        nixfmt = {
          command = [
            "nixfmt"
            "-s"
            "-w"
            "120"
            "$FILE"
          ];
          extensions = [ ".nix" ];
        };
        gofmt = {
          disabled = true;
        };
        goimports = {
          command = [
            "goimports"
            "-w"
            "$FILE"
          ];
          extensions = [ ".go" ];
        };
        sql-formatter = {
          command = [
            "sql-formatter"
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
            "$FILE"
          ];
          extensions = [ ".sql" ];
        };
        topiary-nu = {
          command = [
            "${lib.getExe self'.packages.topiary-nu}"
            "format"
            "--language"
            "nu"
            "$FILE"
          ];
          extensions = [ ".nu" ];
        };
      };
      permission = {
        todoread = "deny";
        todowrite = "deny";
        external_directory = {
          "~/*" = "allow"; # yolo.
          "/tmp/*" = "allow";
        };
      };
      mcp = lib.mkIf cfg.enableMcp {
        github = {
          type = "remote";
          url = "https://api.githubcopilot.com/mcp/";
          headers = {
            Authorization = "Bearer {env:GITHUB_TOKEN}";
          };
          enabled = false;
        };
      };
    };
  };
}
