# Home-manager options for the omp (oh-my-pi) coding agent.
#
# `omp` is the binary packaged by `llm-agents` as `packages.omp`:
# https://github.com/can1357/oh-my-pi
{ lib, ... }: {
  options.dev.omp = {
    enable = lib.mkEnableOption "omp (oh-my-pi) coding agent";
    enableMcp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "MCP server integrations for omp";
    };
    sops.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use sops-backed secrets for omp MCP servers. Disable on machines that
        don't have a registered SSH key in .sops.yaml — the wrapper will still
        let omp start, just without the secret-needing MCPs.
      '';
    };
  };

  imports = [ ./default.nix ];
}
