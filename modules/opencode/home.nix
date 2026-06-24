{ lib, ... }: {
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
    sops.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use sops-backed secrets for opencode MCP servers (Linear, Sentry, GitHub, Kagi).
        Disable on machines that don't have a registered SSH key in .sops.yaml —
        the wrapper will still let opencode start, just without the secret-needing MCPs.
      '';
    };
  };

  imports = [ ./default.nix ];
}
