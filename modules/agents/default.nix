# Coding-agent configuration shared by every agent on this host: the MCP
# servers each one is given, the skills they all read, and one module per agent
# rendering that shared set into the agent's own format. Agent-specific settings
# stay in that agent's own module.
{ config, lib, ... }: {
  imports = [
    ./albedo.nix
    ./mcp.nix
    ./opencode.nix
    ./skills.nix
  ];

  options.dev.agents.enable = lib.mkEnableOption "shared coding-agent configuration";

  config.dev.agents.enable = lib.mkDefault true;
}
