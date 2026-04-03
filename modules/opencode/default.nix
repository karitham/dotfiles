{
  config,
  lib,
  pkgs,
  self',
  ...
}:
let
  opencodePkg = pkgs.symlinkJoin {
    name = "opencode.wrapped";
    paths = [ pkgs.opencode ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/opencode \
        --set SHELL ${lib.getExe pkgs.bash}
    '';
  };

  cfg = config.dev.opencode;
in
lib.mkIf cfg.enable {
  xdg.configFile."opencode/agents" = {
    source = ./agents;
    recursive = true;
  };

  xdg.configFile."opencode/skills" = {
    source = ./skills;
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
      plugin = [ "@mohak34/opencode-notifier@latest" ];
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
        external_directory = lib.genAttrs [ "~/go/pkg/mod/**" ] (_: "allow");
      };
      mcp = lib.mkIf cfg.enableMcp {
        gopls = {
          type = "local";
          enabled = true;
          command = [
            "gopls"
            "mcp"
          ];
        };
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
