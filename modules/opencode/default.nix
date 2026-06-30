{
  config,
  inputs,
  lib,
  pkgs,
  self',
  inputs',
  ...
}:
let
  cfg = config.dev.opencode;

  # Path to the sops-decrypted env file, or /dev/null if not configured.
  # The wrapper uses `[ -f ... ]` to skip if missing, so opencode always starts
  # even on machines where sops can't decrypt.
  opencodeEnvFile =
    if (config.sops.secrets ? "opencode/env") then config.sops.secrets."opencode/env".path else "/dev/null";

  opencodePkg = pkgs.symlinkJoin {
    name = "opencode-wrapped";
    paths = [ inputs'.llm-agents.packages.opencode ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/opencode \
        --run 'if [ -f "${opencodeEnvFile}" ]; then set -a; . "${opencodeEnvFile}"; set +a; fi' \
        --set OPENCODE_EXPERIMENTAL_LSP_TOOL true \
        --set OPENCODE_DISABLE_LSP_DOWNLOAD true \
        --set OPENCODE_DISABLE_AUTOUPDATE true \
        --set OPENCODE_EXPERIMENTAL_MARKDOWN true \
        --set OPENCODE_ENABLE_EXA true \
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
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  config = lib.mkIf cfg.enable {
    sops.secrets."opencode/env" = lib.mkIf cfg.sops.enable {
      sopsFile = ../../secrets/opencode.env;
      format = "dotenv";
    };

    xdg.configFile = {
      "opencode/skills".source = pkgs.symlinkJoin {
        name = "opencode-skills";
        paths = [
          self'.packages.strands-sops-skills
          ./skills
        ];
      };
    };

    programs.opencode = {
      enable = true;
      package = opencodePkg;
      enableMcpIntegration = cfg.enableMcp;
      commands = ./commands;
      agents = ./agents;
      settings = {
        plugin = [ "@mohak34/opencode-notifier@0.2.8" ];
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
          # outline doesn't need secrets, always available
          outline = {
            type = "remote";
            url = "https://outline.dolly-ruffe.ts.net/mcp";
            enabled = true;
          };

          # These need secrets from sops, only configured when sops is enabled
          github = lib.mkIf cfg.sops.enable {
            type = "remote";
            url = "https://api.githubcopilot.com/mcp/";
            enabled = true;
            headers = {
              Authorization = "Bearer {env:GITHUB_TOKEN}";
            };
          };

          kagi = lib.mkIf cfg.sops.enable {
            type = "remote";
            url = "https://mcp.kagi.com/mcp";
            oauth = false;
            enabled = true;
            headers = {
              Authorization = "Bearer {env:KAGI_API_KEY}";
            };
          };

        };
      };
    };
  };
}
