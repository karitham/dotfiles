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

  programs.opencode.settings.mcp = {
    linear = {
      type = "remote";
      url = "https://mcp.linear.app/mcp";
      enabled = true;
      headers = {
        Authorization = "Bearer {env:LINEAR_API_KEY}";
      };
    };
    sentry = {
      type = "remote";
      enabled = true;
      url = "{env:SENTRY_MCP_URL}";
      oauth = { };
    };
  };
}
