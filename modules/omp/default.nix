# omp (oh-my-pi) home-manager module.
#
# Mirrors the shape of ../opencode/default.nix: wrap the llm-agents-built
# binary, prefix the same LSP set on PATH, and source sops-decrypted secrets
# for MCP auth. User-level MCP servers live at ~/.omp/agent/mcp.json
# (per https://omp.sh/docs/mcp-config), which is what omp reads when launched
# with a default profile.
{
  config,
  inputs',
  lib,
  pkgs,
  self',
  ...
}:
let
  cfg = config.dev.omp;

  # Path to the sops-decrypted env file, or /dev/null if not configured.
  # The wrapper uses `[ -f ... ]` to skip if missing, so omp always starts
  # even on machines where sops can't decrypt.
  ompEnvFile = if (config.sops.secrets ? "opencode/env") then config.sops.secrets."opencode/env".path else "/dev/null";

  # Same LSP set as the opencode wrapper, so the two agents are equivalent
  # on the code-intelligence side.
  lspBinPath = lib.makeBinPath [
    self'.packages.golangci-lint-langserver
    pkgs.nixd
    pkgs.marksman
    pkgs.typescript-language-server
    pkgs.vscode-langservers-extracted
    pkgs.yaml-language-server
    pkgs.typos-lsp
    pkgs.nil
  ];

  ompPkg = pkgs.symlinkJoin {
    name = "omp-wrapped";
    paths = [ inputs'.llm-agents.packages.omp ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/omp \
        --run 'if [ -f "${ompEnvFile}" ]; then set -a; . "${ompEnvFile}"; set +a; fi' \
        --set PI_SKIP_VERSION_CHECK 1 \
        --set SHELL "${lib.getExe pkgs.bash}" \
        --prefix PATH : "${lspBinPath}"
    '';
  };

  mcpJson = pkgs.writeText "omp-mcp.json" (
    builtins.toJSON {
      "$schema" = "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
      mcpServers = lib.optionalAttrs cfg.enableMcp (
        {
          # See: https://omp.sh/docs/mcp-config (Auth fields, definition-only)
          github = {
            type = "http";
            url = "https://api.githubcopilot.com/mcp/";
          };
          linear = {
            type = "http";
            url = "https://mcp.linear.app/mcp";
          };
        }
        // lib.optionalAttrs cfg.sops.enable {
          sentry = {
            type = "http";
            url = "\${SENTRY_MCP_URL}";
          };
        }
      );
    }
  );

  configYaml = pkgs.writeText "omp-config.yml" (
    builtins.toJSON {
      symbolPreset = "nerd";
      theme.dark = "dark-catppuccin";
      setupVersion = 1;
      modelRoles = {
        default = "opencode-go/minimax-m3";
        smol = "opencode-go/deepseek-v4-flash";
        tiny = "opencode-go/deepseek-v4-flash";
      };
      providers.webSearch = "exa";
    }
  );
in
{
  config = lib.mkIf cfg.enable {
    home = {
      packages = [ ompPkg ];
      file = {
        ".omp/agent/config.yml" = {
          source = configYaml;
        };
        ".omp/agent/mcp.json" = lib.mkIf cfg.enableMcp { source = mcpJson; };
      };
    };
  };
}
