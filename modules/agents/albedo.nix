# Albedo's side of the shared agent config: the MCP servers, written into
# $ALBEDO_HOME/extensions.json, and a wrapper that puts the agent secrets in
# the daemon's environment, which is where albedo resolves `{ "env": ... }`.
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

  # Server names this repo owns, so a server deleted here is deleted from
  # albedo's config too, while servers added from albedo's own UI stay.
  state = "$HOME/.albedo/nix-mcp.json";
  target = "$HOME/.albedo/extensions.json";

  fragment = pkgs.writeText "albedo-mcp.json" (
    builtins.toJSON {
      servers = lib.mapAttrs (_: render.toAlbedo) cfg.mcpServers;
      enabled.mcp = true;
    }
  );

  render = import ./lib.nix { inherit lib; };

  # Deep merge, nix wins per field: a server declared here is added, its
  # fields are kept current, and every other server, toggle and setting in
  # extensions.json is left alone.
  merge = ''
    def resolve:
      walk(if type == "string" and startswith("@env:")
           then (.[5:] as $name | (env[$name] // .))
           else . end);
    def unresolved: [.. | strings | select(startswith("@env:"))] | length > 0;

    ($f[0] | resolve) as $frag
    | ($frag.servers | with_entries(select(.value | unresolved | not))) as $servers
    | ($servers | keys) as $owned
    | ($before - $owned) as $gone
    | .mcp = (.mcp // {})
    | .mcp.servers = (
        ((.mcp.servers // {}) | with_entries(select(.key as $name | ($gone | index($name)) | not)))
        * $servers
      )
    | .enabled = ((.enabled // {}) * ($frag.enabled // {}))
  '';
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
          # A subshell, so the tools this needs stay out of every other
          # activation entry's PATH.
          (
          export PATH="${
            lib.makeBinPath [
              pkgs.coreutils
              pkgs.jq
            ]
          }:$PATH"

          # Secrets first: the fragment carries @env:NAME@ for URLs that are
          # themselves secret, and jq resolves them from this environment.
          # shellcheck disable=SC1091
          if [ -f "${cfg.envFile}" ]; then set -a; . "${cfg.envFile}"; set +a; fi

          $VERBOSE_ARG mkdir -p "$HOME/.albedo"
          work="$(mktemp -d)"
          trap 'rm -rf "$work"' EXIT

          before='[]'
          if [ -r "${state}" ]; then
            before="$(jq -c '.servers // []' "${state}" 2>/dev/null || echo '[]')"
          fi

          if [ -r "${target}" ]; then
            cp "${target}" "$work/extensions.json"
          else
            echo '{}' > "$work/extensions.json"
          fi

          jq --slurpfile f "${fragment}" --argjson before "$before" '${merge}' \
            "$work/extensions.json" > "$work/merged.json"
          chmod 600 "$work/merged.json"
          $DRY_RUN_CMD mv -f "$work/merged.json" "${target}"

          jq -c -n --slurpfile f "${fragment}" '{ servers: ($f[0].servers | keys) }' > "$work/nix-mcp.json"
          chmod 600 "$work/nix-mcp.json"
          $DRY_RUN_CMD mv -f "$work/nix-mcp.json" "${state}"
          )
        '';
  };
}
