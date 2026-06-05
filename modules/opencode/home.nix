{ lib, pkgs, ... }:
{
  options.dev.opencode = {
    enable = lib.mkEnableOption "OpenCode AI-assisted development environment";
    enableMcp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "MCP server integrations for enhanced language support";
    };
    theme = lib.mkOption {
      type = lib.types.str;
      default = "catppuccin-macchiato";
      description = "OpenCode theme";
    };
    enableDiffViewer = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install codiff — local diff viewer for code review";
    };
  };

  imports = [ ./default.nix ];
}
