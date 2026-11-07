# Installs the albedo configuration this flake builds into a home: the MCP
# servers, the shared skills, and the Exa key when the environment carries one.
# Home-manager runs it on activation; an image with no home-manager runs it
# before the daemon starts (./albedo-config.nix), so both install the same
# things the same way.
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
    state="$home/.albedo/nix-mcp.json"
    creds="$home/.albedo/creds.json"

    run install -d -m 700 "$home/.albedo"

    # A server the fragment carried last time but does not carry now was
    # deleted in the flake, so the entry it left behind goes too.
    before='[]'
    if [ -r "$state" ]; then
      before="$(jq -c '.servers // []' "$state" 2>/dev/null || printf '[]')"
    fi

    if [ -r "$target" ]; then
      cp "$target" "$work/extensions.json"
    else
      printf '{}\n' > "$work/extensions.json"
    fi

    jq --slurpfile f "$fragment" --argjson before "$before" \
      -f ${./albedo-merge.jq} "$work/extensions.json" > "$work/merged.json"
    chmod 600 "$work/merged.json"
    # A server whose @env: reference does not resolve here is left out, so the
    # summary comes from what the merge produced, not from the fragment.
    installed="$(jq -r '.mcp.servers | keys | join(", ")' "$work/merged.json")"
    run mv -f "$work/merged.json" "$target"

    jq -c -n --slurpfile f "$fragment" '{ servers: ($f[0].servers | keys) }' > "$work/nix-mcp.json"
    chmod 600 "$work/nix-mcp.json"
    run mv -f "$work/nix-mcp.json" "$state"

    # Exa reads its key from creds.json rather than from the environment, so
    # one in this environment is copied in. Only a changed key rewrites the
    # file: every other section belongs to albedo, and rewriting an identical
    # one would race its own writes.
    if [ -n "''${EXA_API_KEY:-}" ]; then
      saved="$(jq -r '.exa.apiKey // ""' "$creds" 2>/dev/null || true)"
      if [ "$saved" != "$EXA_API_KEY" ]; then
        if [ -r "$creds" ]; then
          cp "$creds" "$work/creds.json"
        else
          printf '{}\n' > "$work/creds.json"
        fi
        jq --arg key "$EXA_API_KEY" '.exa.apiKey = $key' "$work/creds.json" > "$work/creds-next.json"
        chmod 600 "$work/creds-next.json"
        run mv -f "$work/creds-next.json" "$creds"
      fi
    fi

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
