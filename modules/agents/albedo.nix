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

  creds = "${config.home.homeDirectory}/.albedo/creds.json";
  keyPath = lib.makeBinPath [
    pkgs.coreutils
    pkgs.jq
  ];

  # Fingerprint of the secrets the running daemon was started with. The daemon
  # reads its environment once, at exec, so a rotated token only reaches it
  # through a restart; this tells an activation whether the file really changed.
  envFingerprint = "${config.xdg.stateHome}/albedo/mcp-environment.sha256";
in
{
  imports = [ inputs.albedo.homeModules.default ];

  options.dev.albedo.enable = lib.mkEnableOption "the Albedo coding agent";

  config = lib.mkIf albedo.enable {
    programs.albedo.enable = true;

    # ./servers.nix declares every server once, for every agent: the module
    # reads a token from an `Authorization = "Bearer {env:TOKEN}"` header as its
    # own bearerTokenEnvVar, so the secret-bearing servers need no second,
    # albedo-shaped copy here.
    services.albedo = {
      enable = true;
      enableMcpIntegration = true;
    };

    # The daemon reads its environment once, at exec: a shell that has the
    # secrets is not enough, so the service gets the decrypted dotenv file
    # instead of the wrapper that used to source it. sops-nix writes that file at
    # login, so the daemon waits for it; the file is required rather than
    # optional, because a daemon started without it connects none of the servers
    # that name a token and says so per server, long after the mistake.
    systemd.user.services.albedo = lib.mkIf cfg.sops.enable {
      Unit = {
        Wants = [ "sops-nix.service" ];
        After = [ "sops-nix.service" ];
      };
      Service.EnvironmentFile = "${cfg.envFile}";
    };

    # sops-nix rewrites the dotenv on every activation, and systemd only notices
    # a unit whose text changed, so nothing would restart the daemon after a
    # token is rotated. Restart it here instead, and only when the contents
    # differ from what it was started with, so an unchanged file does not
    # interrupt a turn. The fingerprint is a hash, so no secret is copied.
    home.activation.albedoEnvFingerprint = lib.mkIf cfg.sops.enable (
      lib.hm.dag.entryAfter [ "writeBoundary" "sops-nix" ] ''
        (
        export PATH=${keyPath}:$PATH
        export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

        env_file=${lib.escapeShellArg cfg.envFile}
        fingerprint=${lib.escapeShellArg envFingerprint}

        if [ ! -r "$env_file" ]; then
          warnEcho "The agents' secrets are missing at $env_file; albedo cannot start until they exist."
        else
          install -d -m 700 "$(dirname "$fingerprint")"
          current="$(sha256sum "$env_file" | cut -d' ' -f1)"
          if [ "$current" != "$(cat "$fingerprint" 2>/dev/null || true)" ]; then
            (umask 077 && printf '%s\n' "$current" > "$fingerprint")
            # Restarts only a running daemon; otherwise the next start reads the
            # new file anyway.
            ${config.systemd.user.systemctlPath} --user try-restart albedo.service ||
              warnEcho "albedo did not restart; restart it to pick up the new secrets."
          fi
        fi
        )
      ''
    );

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
