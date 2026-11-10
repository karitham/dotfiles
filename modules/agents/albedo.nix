# Albedo, through its own home-manager module: the client package, the daemon as
# a user service, and the MCP servers every agent shares (./servers.nix), which
# that module merges into $ALBEDO_HOME/extensions.json on activation.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  albedo = config.dev.albedo;
  cfg = config.dev.agents;

  render = import ./lib.nix { inherit lib; };

  # A shared server the environment authenticates cannot be imported as written:
  # albedo sends its bearer token as a variable read from the daemon's
  # environment, never as a header. The import replaces a declared server of the
  # same name as a whole, so the restated one is complete (./lib.nix) and only
  # these servers need restating.
  restatements = lib.optionalAttrs (cfg.enable && config.programs.mcp.enable) (
    lib.mapAttrs (_: render.toAlbedo) (lib.filterAttrs (_: server: server ? bearerTokenEnvVar) config.programs.mcp.servers)
  );

  creds = "${config.home.homeDirectory}/.albedo/creds.json";
  keyPath = lib.makeBinPath [
    pkgs.coreutils
    pkgs.jq
  ];
in
{
  imports = [ inputs.albedo.homeModules.default ];

  options.dev.albedo.enable = lib.mkEnableOption "the Albedo coding agent";

  config = lib.mkIf albedo.enable {
    programs.albedo.enable = true;

    services.albedo = {
      enable = true;
      enableMcpIntegration = true;
      settings.extensions.mcp.servers = restatements;
    };

    # The daemon reads its environment once, at exec: a shell that has the
    # secrets is not enough, so the service gets the decrypted dotenv file
    # instead of the wrapper that used to source it.
    systemd.user.services.albedo.Service.EnvironmentFile = lib.mkIf cfg.sops.enable "-${cfg.envFile}";

    # Exa reads its key from creds.json rather than from the environment, and
    # creds.json is albedo's own file (the module only manages the settings
    # documents), so the key from the decrypted secrets is copied in. A subshell,
    # so sourcing the secrets stays out of every other activation entry.
    home.activation.albedoExaKey = lib.mkIf cfg.sops.enable (
      lib.hm.dag.entryAfter [ "writeBoundary" "sops-nix" ] ''
        (
        export PATH=${keyPath}:$PATH
        # shellcheck disable=SC1091
        source ${./albedo-exa-key.sh}

        set -a
        # shellcheck disable=SC1091
        if [ -f "${cfg.envFile}" ]; then . "${cfg.envFile}"; fi
        set +a

        albedo_exa_key ${lib.escapeShellArg creds}
        )
      ''
    );
  };
}
