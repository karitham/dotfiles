# Home-manager content for the `work` tag. Shared by the NixOS path
# (via ./work.nix) and the standalone homeConfigurations of work-tagged
# hosts (via ../../flake-parts.nix, homeModules.work).
{ ... }: {
  xdg.configFile."git/config".text = ''
    [includeIf "hasconfig:remote.*.url:git+ssh://git@github.com/upfluence/**"]
        path = "~/upf/.gitconfig"
    [includeIf "hasconfig:remote.*.url:git@github.com:upfluence/**"]
        path = "~/upf/.gitconfig"
  '';

  # Work's MCP servers, in the shared shape (modules/agents): opencode and
  # albedo are both generated from these.
  dev.agents.mcpServers = {
    linear = {
      type = "http";
      url = "https://mcp.linear.app/mcp";
      bearerEnv = "LINEAR_API_KEY";
    };
    sentry = {
      type = "http";
      urlEnv = "SENTRY_MCP_URL";
      oauth = { };
    };
  };
}
