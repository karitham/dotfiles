{
  config,
  lib,
  pkgs,
  self',
  inputs',
  osConfig,
  ...
}:
let
  lumenPkg = pkgs.symlinkJoin {
    name = "lumen-wrapped";
    paths = [ self'.packages.lumen ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/lumen \
        --set LUMEN_BACKEND "lmstudio" \
        --set LUMEN_EMBED_MODEL "jina-embeddings-v2-base-code" \
        --set LUMEN_EMBED_DIMS "768"
    '';
  };

  opencodePkg = pkgs.symlinkJoin {
    name = "opencode-wrapped";
    paths = [ inputs'.llm-agents.packages.opencode ];

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
            self'.packages.golangci-lint-langserver
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

  embedModel = pkgs.fetchurl {
    url = "https://huggingface.co/second-state/jina-embeddings-v2-base-code-GGUF/resolve/main/jina-embeddings-v2-base-code-f16.gguf";
    hash = "sha256-ypgps2nHFeSG6f337JvuP5GtkQKNhnIgu2hnMpR7ZaU=";
  };

  cfg = config.dev.opencode;
  osCfg = osConfig.dev.opencode;
in
lib.mkIf osCfg.enable {
  xdg.configFile."opencode/skills".source = pkgs.symlinkJoin {
    name = "opencode-skills";
    paths = [
      self'.packages.strands-sops-skills
      ./skills
    ];
  };

  xdg.configFile."opencode/plugins/skills-reminder.ts".source = ./plugins/skills-reminder.ts;

  home.packages = [ lumenPkg ];

  programs.opencode = {
    enable = true;
    package = opencodePkg;
    enableMcpIntegration = cfg.enableMcp;
    context = ./AGENTS.md;
    commands = ./commands;
    agents = ./agents;
    settings = {
      plugin = [
        "@mohak34/opencode-notifier@0.2.2"
        "@ory/lumen-opencode"
      ];
      experimental = {
        batch_tool = true;
      };
      lsp = { };
      inherit (cfg) theme;
      default_agent = "orchestrator";
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
        nufmt = {
          command = [
            "nufmt"
            "--stdin"
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

        lumen = {
          type = "local";
          command = [
            (lib.getExe' lumenPkg "lumen")
            "stdio"
          ];
          enabled = true;
        };
      };
    };
  };

  systemd.user.services.llama-embedding = {
    Unit = {
      Description = "llama.cpp embedding server for lumen";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe' cfg.llamaPackage "llama-server"} --embedding --host 127.0.0.1 --port 1234 --alias jina-embeddings-v2-base-code --ubatch-size 2048 -m ${embedModel}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
