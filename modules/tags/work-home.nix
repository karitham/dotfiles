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

  # Work's MCP servers, in home-manager's shared shape: opencode imports them
  # through enableMcpIntegration, albedo through its own module. A server the
  # environment authenticates names its token twice (../agents/servers.nix says
  # why): opencode sends the header, albedo reads `bearerTokenEnvVar`.
  programs.mcp.servers = {
    linear = {
      type = "http";
      url = "https://mcp.linear.app/mcp";
      headers.Authorization = "Bearer {env:LINEAR_API_KEY}";
      bearerTokenEnvVar = "LINEAR_API_KEY";
    };

    # Sentry's hosted MCP signs in with OAuth, so the endpoint carries no
    # credential and needs no scope: both clients start their own sign-in, and
    # whoever has one organization gets it as the default without naming it.
    sentry = {
      type = "http";
      url = "https://mcp.sentry.dev/mcp";
    };
  };
}
