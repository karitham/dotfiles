# The MCP servers every agent on the host is given, in one transport-neutral
# shape, and nothing about the way an install delivers them. ./mcp.nix adds the
# home-manager side (sops), and the flake renders this same set into albedo's
# own config for a machine home-manager never touches (./albedo-config.nix).
#
# A tag module adds a host's own servers with
# `dev.agents.mcpServers.<name> = { ... };`.
{
  config,
  lib,
  self',
  ...
}:
let
  cfg = config.dev.agents;

  # A header or environment value is a literal, or a reference to a variable
  # the agent resolves when it connects.
  source = lib.types.either lib.types.str (
    lib.types.submodule {
      options.env = lib.mkOption {
        type = lib.types.str;
        description = "Name of the environment variable holding the value.";
      };
    }
  );

  server = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.enum [
          "http"
          "stdio"
        ];
        description = "An HTTP endpoint, or a command spoken to over stdio.";
      };
      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Endpoint of an HTTP server.";
      };
      urlEnv = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Environment variable holding the whole endpoint, for a URL that is
          itself a secret. Albedo cannot reference a variable in `url`, so its
          config carries the value substituted at activation.
        '';
      };
      bearerEnv = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Environment variable holding a token sent as `Authorization: Bearer $VAR`.";
      };
      headers = lib.mkOption {
        type = lib.types.attrsOf source;
        default = { };
        description = "Extra headers of an HTTP server.";
      };
      oauth = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.bool lib.types.attrs);
        default = null;
        description = ''
          OpenCode's OAuth settings; `false` stops it probing for one. Albedo
          has no equivalent and starts its own sign-in whenever a server asks
          for one.
        '';
      };
      command = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Command and arguments of a stdio server.";
      };
      env = lib.mkOption {
        type = lib.types.attrsOf source;
        default = { };
        description = "Environment of a stdio server.";
      };
      cwd = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Working directory of a stdio server.";
      };
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Off keeps the definition without connecting to it.";
      };
      timeoutMs = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Per-request timeout in milliseconds.";
      };
      startupTimeoutMs = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "How long a session waits for the server to start. Albedo only.";
      };
    };
  };
in
{
  options.dev.agents = {
    enable = lib.mkEnableOption "shared coding-agent configuration";

    secretServers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Include the servers that need a secret from the environment. A host
        that holds the secrets itself (home-manager decrypts them with sops, a
        container gets them from its deployment) says so here, so the servers
        without one stay declared and switched off.
      '';
    };

    mcpBrowser = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = ''
        Browser the chrome-devtools MCP drives, passed as --executablePath.
        Null leaves the flag off and lets the server look for a Chrome itself.
        Desktop hosts set this to helium (modules/desktop/apps/browser.nix);
        override it per host to use a different browser.
      '';
    };

    attachBrowser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        DevToolsActivePort file of a browser that is already running, as a path
        this machine can read. When set, the chrome-devtools MCP attaches to
        that browser over CDP instead of launching one, so the agent sees the
        tabs and logged-in sessions of the user's own profile.

        The file holds two lines: the CDP port, then the
        /devtools/browser/<uuid> socket path. Chromium serves no
        /json/version on that implicit endpoint, so the server needs
        --wsEndpoint rather than --browserUrl, and it must read the file at
        connect time because the uuid changes on every browser start.
      '';
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf server;
      default = { };
      description = ''
        MCP servers every agent on this host is given. Declared here or in a
        tag module; rendered into each agent's own config by ./lib.nix.
      '';
    };
  };

  config = {
    dev.agents.enable = lib.mkDefault true;

    dev.agents.mcpServers = lib.mkIf cfg.enable (
      {
        # outline doesn't need secrets, always available
        outline = {
          type = "http";
          url = "https://outline.dolly-ruffe.ts.net/mcp";
        };

        # Off unless a host points it at a running browser: the fallback
        # branch launches one, which is a blank profile and no sessions.
        chrome-devtools = {
          type = "stdio";
          enabled = cfg.attachBrowser != null;
          command =
            if cfg.attachBrowser != null then
              [
                "bash"
                "-lc"
                (
                  "f=${lib.escapeShellArg cfg.attachBrowser}; "
                  + "exec ${lib.getExe self'.packages.chrome-devtools-mcp} "
                  + "--wsEndpoint \"ws://127.0.0.1:$(sed -n 1p \"$f\")$(sed -n 2p \"$f\")\""
                )
              ]
            else
              [ (lib.getExe self'.packages.chrome-devtools-mcp) ]
              ++ lib.optionals (cfg.mcpBrowser != null) [
                "--executablePath"
                (lib.getExe cfg.mcpBrowser)
              ];
        };
      }
      // lib.optionalAttrs cfg.secretServers {
        # These need a secret from the environment, so they only appear where
        # the host has one to give.
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp/";
          bearerEnv = "GITHUB_TOKEN";
        };

        kagi = {
          type = "http";
          url = "https://mcp.kagi.com/mcp";
          bearerEnv = "KAGI_API_KEY";
          oauth = false;
          enabled = false;
        };
      }
    );
  };
}
