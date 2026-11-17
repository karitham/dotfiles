# Home-manager content for the `work` tag. Shared by the NixOS path
# (via ./work.nix) and the standalone homeConfigurations of work-tagged
# hosts (via ../../flake-parts.nix, homeModules.work).
{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."git/config".text = ''
    [includeIf "hasconfig:remote.*.url:git+ssh://git@github.com/upfluence/**"]
        path = "~/upf/.gitconfig"
    [includeIf "hasconfig:remote.*.url:git@github.com:upfluence/**"]
        path = "~/upf/.gitconfig"
  '';

  # Work's MCP servers, in home-manager's shared shape: opencode imports them
  # through enableMcpIntegration, albedo through its own module.
  programs.mcp.servers = {
    linear = {
      type = "http";
      url = "https://mcp.linear.app/mcp";
    };

    sentry = {
      type = "http";
      url = "https://mcp.sentry.dev/mcp";
    };

    grafana = {
      type = "stdio";
      command = lib.getExe pkgs.mcp-grafana;
      env.GRAFANA_URL.file = "${config.xdg.configHome}/grafana/url";
      env.GRAFANA_EXTRA_HEADERS.file = "${config.xdg.configHome}/grafana/mcp-headers.json";
    };
  };
}
