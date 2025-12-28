{
  lib,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "hayase"
    ];
  home.packages = [
    pkgs.signal-desktop-bin
    pkgs.obs-studio
    pkgs.hayase
  ];

  programs = {
    waybar.settings.mainBar.battery.bat = lib.mkForce "BAT0";
    opencode.settings.mcp = {
      linear = {
        type = "remote";
        url = "https://mcp.linear.app/mcp";
        enabled = true;
        headers = {
          Authorization = "Bearer {env:LINEAR_API_KEY}";
        };
      };
      sentry = {
        type = "local";
        enabled = true;
        command = ["${pkgs.bun}/bin/bun" "x" "mcp-remote@latest" "https://mcp.sentry.dev/mcp"];
      };
    };
  };
}
