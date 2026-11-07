# Albedo's side of the shared agent config: the MCP servers, merged into
# $ALBEDO_HOME/extensions.json on activation, and a wrapper that puts the agent
# secrets in the daemon's environment, which is where albedo resolves
# `{ "env": ... }`.
{
  config,
  lib,
  pkgs,
  inputs',
  ...
}:
let
  cfg = config.dev.agents;
  albedo = config.dev.albedo;

  base = inputs'.albedo.packages.default;

  # The wrapper exists because the daemon reads its environment once, at exec:
  # a shell that has the secrets is not enough, the process albedo starts must
  # inherit them.
  package = pkgs.writeShellApplication {
    name = "albedo";
    meta = base.meta or { };
    passthru = base.passthru or { };
    derivationArgs.version = base.version or "0";
    text = ''
      # shellcheck disable=SC1091
      if [ -f "${cfg.envFile}" ]; then set -a; . "${cfg.envFile}"; set +a; fi

      exec ${lib.getExe base} "$@"
    '';
  };

  fragment = pkgs.writeText "albedo-mcp.json" (
    builtins.toJSON {
      servers = lib.mapAttrs (_: render.toAlbedo) cfg.mcpServers;
      enabled.mcp = true;
    }
  );

  render = import ./lib.nix { inherit lib; };

  # The install itself is shared with the image the infra repo builds, so a
  # merged extensions.json looks the same on a desktop and in a container.
  seed = import ./albedo-seed.nix {
    inherit lib pkgs;
    inherit fragment;
  };
in
{
  options.dev.agents.albedo = {
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = package;
      description = "The albedo CLI, wrapped to carry the agent secrets.";
    };
    writeConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Merge dev.agents.mcpServers into $ALBEDO_HOME/extensions.json on
        activation. Off leaves albedo's MCP servers to albedo's own /mcp.
      '';
    };
  };

  config = lib.mkIf (albedo.enable && cfg.enable && cfg.albedo.writeConfig) {
    home.activation.albedoMcp =
      lib.hm.dag.entryAfter ([ "writeBoundary" ] ++ lib.optional (cfg.envFile != "/dev/null") "sops-nix")
        ''
          # A subshell, so sourcing the secrets stays out of every other
          # activation entry's environment.
          (
          # Secrets first: the fragment carries @env:NAME for URLs that are
          # themselves secret, and the seed resolves them from this
          # environment. It also copies EXA_API_KEY into creds.json, which is
          # the only place Exa looks for it.
          # shellcheck disable=SC1091
          if [ -f "${cfg.envFile}" ]; then set -a; . "${cfg.envFile}"; set +a; fi

          ${lib.getExe seed} ''${DRY_RUN_CMD:+--dry-run}
          )
        '';
  };
}
