{ config, ... }:
{
  desktop.yubikey.enable = true;
  programs._1password.enable = true;

  home-manager.users.${config.my.username} = {
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
        enabled = false; # disable by default because it breaks google models
        headers = {
          Authorization = "Bearer {env:LINEAR_API_KEY}";
        };
      };
      sentry = {
        type = "remote";
        enabled = false;
        url = "{env:SENTRY_MCP_URL}";
        oauth = { };
      };
    };
  };
}
