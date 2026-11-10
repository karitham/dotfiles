# Coding-agent configuration shared by every agent on this host: the MCP servers
# they are given, declared once in home-manager's `programs.mcp.servers`
# (./servers.nix), the skills they all read, and one module per agent, which
# imports that shared set into its own format. Agent-specific settings stay in
# that agent's own module.
{ ... }: {
  imports = [
    ./albedo.nix
    ./mcp.nix
    ./opencode.nix
    ./skills.nix
  ];
}
