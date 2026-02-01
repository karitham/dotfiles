{ lib, ... }:
{
  options.dev.opencode = {
    enable = lib.mkEnableOption "OpenCode AI-assisted development environment";
    enableLangRules = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "LangRules plugin injects language specific context and tooling";
    };
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
  };

  imports = [ ./default.nix ];
}
