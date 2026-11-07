# The home-manager side of the shared MCP servers (./mcp-servers.nix): the
# encrypted secrets they read, and the hosts that have them. The servers
# themselves live in the module this one imports, so the flake can evaluate
# them without home-manager for an image that home-manager never configures.
{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.dev.agents;
in
{
  imports = [
    ./mcp-servers.nix
    inputs.sops-nix.homeManagerModules.sops
  ];

  options.dev.agents = {
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
  };

  config = {
    # A host whose secrets decrypt is a host whose secret-bearing servers have
    # something to send; ./mcp-servers.nix only knows that second fact.
    dev.agents.secretServers = lib.mkDefault cfg.sops.enable;

    sops.secrets."agents/env" = lib.mkIf cfg.sops.enable {
      sopsFile = ../../secrets/agents.env;
      format = "dotenv";
    };
  };
}
