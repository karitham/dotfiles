# The home-manager side of the shared MCP servers (./servers.nix): the encrypted
# secrets they read, the hosts that have them, and the declaration itself —
# `programs.mcp.servers`, which every client on this host is fed from (opencode
# through enableMcpIntegration, albedo through its own module in ./albedo.nix).
{
  config,
  inputs,
  lib,
  pkgs,
  self',
  ...
}:
let
  cfg = config.dev.agents;

  servers = import ./servers.nix {
    inherit lib pkgs self';
    inherit (cfg) mcpBrowser attachBrowser secretServers;
  };
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  options.dev.agents = {
    enable = lib.mkEnableOption "shared coding-agent configuration";

    sops = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          This host has a key in .sops.yaml, so the agent secrets decrypt. Off
          drops every secret-bearing MCP server and leaves the agents running
          without them.
        '';
      };
    };

    envFile = lib.mkOption {
      type = lib.types.path;
      readOnly = true;
      default = lib.attrByPath [ "agents/env" "path" ] "/dev/null" config.sops.secrets;
      description = "Decrypted dotenv file holding the agents' secrets.";
    };

    secretServers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Include the servers that need a secret from the environment. A host that
        holds the secrets itself (home-manager decrypts them with sops, a
        container gets them from its deployment) says so here, so the servers
        without one stay declared and switched off.
      '';
    };

    mcpBrowser = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = ''
        Browser the chrome-devtools MCP drives, passed as --executablePath. Null
        leaves the flag off and lets the server look for a Chrome itself.
        Desktop hosts set this to helium (modules/desktop/apps/browser.nix);
        override it per host to use a different browser.
      '';
    };

    attachBrowser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        DevToolsActivePort file of a browser that is already running, as a path
        this machine can read. When set, the chrome-devtools MCP attaches to that
        browser over CDP instead of launching one, so the agent sees the tabs and
        logged-in sessions of the user's own profile, and the server is switched
        on.
      '';
    };
  };

  config = {
    dev.agents.enable = lib.mkDefault true;

    # A host whose secrets decrypt is a host whose secret-bearing servers have
    # something to send; ./servers.nix only knows that second fact.
    dev.agents.secretServers = lib.mkDefault cfg.sops.enable;

    sops.secrets."agents/env" = lib.mkIf cfg.sops.enable {
      sopsFile = ../../secrets/agents.env;
      format = "dotenv";
    };

    programs.mcp = lib.mkIf cfg.enable {
      enable = true;
      inherit servers;
    };
  };
}
