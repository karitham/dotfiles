# Installs the albedo configuration this flake builds into a home: the MCP
# servers, the shared skills, and the Exa key when the environment carries one.
# An image with no home-manager runs it before the daemon starts
# (./albedo-config.nix); a home home-manager manages needs none of it, because
# its module (./albedo.nix) merges the same servers on activation.
{
  lib,
  pkgs,
  # The fragment to install unless the caller passes --fragment, and the skills
  # to link unless the caller passes --skills. Both are store paths baked into
  # the script, so it carries what it installs.
  fragment,
  skills ? null,
}:
pkgs.writeShellApplication {
  name = "albedo-seed";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.jq
  ];
  text = ''
    fragment=${lib.escapeShellArg "${fragment}"}
    skills_root=${lib.escapeShellArg (if skills == null then "" else "${skills}")}
    home="''${HOME:-/root}"
    dry_run=""

    usage() {
      printf '%s\n\n' 'Install the albedo configuration built with this script into a home.'
      printf '%s\n' 'albedo-seed [--home DIR] [--fragment FILE] [--skills DIR] [--dry-run]'
      printf '\n%s\n' \
        '  --home DIR      home to write into (default: the HOME variable, then /root)' \
        '  --fragment FILE extensions.json fragment to merge (default: the one built with this script)' \
        '  --skills DIR    skills to link into ~/.agents/skills (default: the ones built with this script; empty for none)' \
        '  --dry-run       print each command instead of running it'
    }

    while [ $# -gt 0 ]; do
      case "$1" in
        --home) home="$2"; shift 2 ;;
        --fragment) fragment="$2"; shift 2 ;;
        --skills) skills_root="$2"; shift 2 ;;
        --dry-run) dry_run=1; shift ;;
        -h | --help) usage; exit 0 ;;
        *)
          printf 'albedo-seed: unknown argument: %s\n' "$1" >&2
          usage >&2
          exit 2
          ;;
      esac
    done

    run() {
      if [ -n "$dry_run" ]; then
        printf '+ %s\n' "$*"
      else
        "$@"
      fi
    }

    work="$(mktemp -d)"
    trap 'rm -rf "$work"' EXIT

    target="$home/.albedo/extensions.json"
    creds="$home/.albedo/creds.json"

    run install -d -m 700 "$home/.albedo"

    if [ -r "$target" ]; then
      cp "$target" "$work/extensions.json"
    else
      printf '{}\n' > "$work/extensions.json"
    fi

    # The declared servers and toggles win, and everything else albedo wrote —
    # the servers it added itself, a server switched off in /mcp, its settings —
    # stays. A server dropped from the flake keeps its entry, exactly as it does
    # on a host home-manager merges for.
    jq --slurpfile f "$fragment" \
      '.mcp.servers = ((.mcp.servers // {}) * ($f[0].servers // {}))
       | .enabled = ((.enabled // {}) * ($f[0].enabled // {}))' \
      "$work/extensions.json" > "$work/merged.json"
    chmod 600 "$work/merged.json"
    installed="$(jq -r '(.mcp.servers // {}) | keys | join(", ")' "$work/merged.json")"
    run mv -f "$work/merged.json" "$target"

    # Exa reads its key from creds.json rather than from the environment, so one
    # in this environment is copied in. The same function backs home-manager's
    # activation (./albedo-exa-key.sh).
    # shellcheck disable=SC1091
    source ${./albedo-exa-key.sh}
    albedo_exa_key "$creds" run

    # One symlink per skill, so a skill added by hand stays and a skill that
    # moved in the flake lands on the next run. A symlinked skills root was put
    # there by home-manager and owns the directory.
    if [ -n "$skills_root" ] && [ -d "$skills_root" ]; then
      if [ -L "$home/.agents/skills" ]; then
        printf 'albedo-seed: %s is a symlink, leaving the skills to it\n' "$home/.agents/skills"
      else
        run install -d -m 755 "$home/.agents/skills"
        for skill in "$skills_root"/*; do
          [ -e "$skill" ] || continue
          name="$(basename "$skill")"
          if [ -e "$home/.agents/skills/$name" ] && [ ! -L "$home/.agents/skills/$name" ]; then
            printf 'albedo-seed: %s exists and is not a link, leaving it\n' "$home/.agents/skills/$name" >&2
            continue
          fi
          run ln -sfnT "$skill" "$home/.agents/skills/$name"
        done
      fi
    fi

    printf 'albedo-seed: %s -> %s\n' "$installed" "$target"
  '';
}
