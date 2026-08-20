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
  opencodeEnvFile = lib.attrByPath [ "opencode/env" "path" ] "/dev/null" config.sops.secrets;

  opencodePkg' =
    pkg: name:
    pkgs.symlinkJoin {
      name = "opencode-wrapped";
      paths = [ pkg ];

      nativeBuildInputs = [ pkgs.makeWrapper ];

      postBuild = ''
        wrapProgram $out/bin/${name} \
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

    home.packages = [ (opencodePkg' inputs'.llm-agents.packages.opencode2 "opencode2") ];

    programs.opencode = {
      enable = true;
      package = opencodePkg' inputs'.llm-agents.packages.opencode "opencode";
      enableMcpIntegration = cfg.enableMcp;
      commands = ./commands;
      agents = ./agents;
      skills = ./skills;
      settings = {
        plugin = [ "@mohak34/opencode-notifier@0.2.8" ];
        experimental = {
          batch_tool = true;
        };
        lsp = { };
        inherit (cfg) theme;
        default_agent = "pair";
        agent = {
          explore = {
            model = "opencode-go/deepseek-v4-flash";
            variant = "high";
          };
        };
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
            enabled = false;
            headers = {
              Authorization = "Bearer {env:KAGI_API_KEY}";
            };
          };

          # Packaged from the npm tarball in pkgs/browsermcp.nix; the bin
          # carries its own node shebang, so no JS runtime is needed on PATH.
          browsermcp = {
            type = "local";
            enabled = true;
            command = [ "${self'.packages.browsermcp}/bin/mcp-server-browsermcp" ];
          };
        };
      };
    };
  };
}
