{
  lib,
  config,
  pkgs,
  inputs',
  ...
}:
{
  config = lib.mkIf config.desktop.enable {
    home.packages = [
      pkgs.firefox
      inputs'.helium.packages.default
    ];

    # The chrome-devtools MCP would otherwise hunt for a Chrome, and this
    # machine has none.
    dev.opencode.mcpBrowser = lib.mkDefault inputs'.helium.packages.default;
  };
}
