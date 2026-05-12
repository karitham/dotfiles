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
    llamaPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp;
      description = "llama.cpp package to use for the embedding server";
    };
  };

  imports = [ ./default.nix ];
}
