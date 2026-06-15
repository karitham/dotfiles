#!/usr/bin/env -S nu --no-config-file
# jj-review: PR review workflow with jj, prr, hx, and zellij.
# Requires: jj, gh, git, prr, hx (helix), zellij.

# ── helpers ──────────────────────────────────────────────────────────

def fetch-head [meta: record] {
    if $meta.isCrossRepository {
        let owner = $meta.headRepositoryOwner.login
        let repo_url = $meta.headRepository.url
        let existing = git remote | lines
        if not ($owner in $existing) {
            jj git remote add $owner $repo_url
        }
        jj git fetch --remote $owner
    } else {
        jj git fetch --remote origin
    }
}

# ── Squash the PR and open zellij ─────────────────────────────────

# Squash all PR commits onto trunk (or --base), land in the squash,
# then open helix + prr in a zellij tab.
def main [
    url: string
    --base: string       # jj revset to squash onto (default: trunk())
] {
    # Fetch PR metadata — inline to avoid lazy-stream issues with from json
    let raw = (
        do { gh pr view $url --json "number,title,baseRefName,headRefName,isCrossRepository,headRepository,headRepositoryOwner,headRefOid,baseRefOid" }
        | complete
    )
    if $raw.exit_code != 0 {
        error make {msg: $"gh pr view failed: ($raw.stderr)"}
    }
    let meta = $raw.stdout | str trim | from json

    let cwd = (pwd)
    let pr_ref = $"($meta.headRepositoryOwner.login)/($meta.headRepository.name)/($meta.number)"
    let base_rev = (if $base == null { "trunk()" } else { $base })
    let head_oid = $meta.headRefOid
    let base_oid = $meta.baseRefOid

    print $"Fetching PR #($meta.number)..."
    fetch-head $meta

    print $"Squashing onto ($base_rev)..."
    jj new $base_rev
    jj squash --ignore-immutable -m $"Squashed PR #($meta.number) for review.\njj-review: head=($meta.headRefOid) base=($meta.baseRefOid)" -t @ -f $"($meta.baseRefOid)..($meta.headRefOid)"

    print $"Fetching prr file..."
    try { prr get $pr_ref } catch { print "Warning: prr get failed (no token?)" }

    let path_str = $env.PATH | str join ":"
    let env_path = $env | get --optional NIX_LD_LIBRARY_PATH | default ""
    let hx_cmd = "$env.PATH = '" + $path_str + "'; $env.NIX_LD_LIBRARY_PATH = '" + $env_path + "'; hx"
    let prr_cmd = "$env.PATH = '" + $path_str + "'; $env.GITHUB_TOKEN = '" + ($env | get --optional GITHUB_TOKEN | default "") + "'; $env.NIX_LD_LIBRARY_PATH = '" + $env_path + "'; prr edit " + $pr_ref

    let layout = '
layout {
    default_tab_template {
        pane split_direction="vertical" {
            pane {
                command "nu"
                cwd "' + $cwd + '"
                args "-c" "' + $hx_cmd + '"
            }
            pane {
                command "nu"
                cwd "' + $cwd + '"
                args "-c" "' + $prr_cmd + '"
            }
        }
    }
}
'
    print "Opening zellij with helix (left) and prr (right)…"
    zellij --layout-string $layout
}
