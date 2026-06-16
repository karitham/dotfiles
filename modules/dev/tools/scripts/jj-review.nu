#!/usr/bin/env -S nu --no-config-file
# jj-review: PR review workflow with jj, prr, hx, and zellij.
# Requires: jj, gh, git, prr, hx (helix), zellij.

# ── helpers ──────────────────────────────────────────────────────────

def fetch-pr [meta: record] {
    # Always fetch origin — owns the base branch (PR's target).
    jj git fetch --remote origin

    # For cross-repo PRs, also fetch the fork to get the head.
    if $meta.isCrossRepository {
        let owner = $meta.headRepositoryOwner.login
        let repo_url = $meta.headRepository.url
        let existing = git remote | lines
        if not ($owner in $existing) {
            jj git remote add $owner $repo_url
        }
        jj git fetch --remote $owner
    }
}

# ── Squash the PR and open zellij ─────────────────────────────────

# Squash all PR commits onto the PR's target branch (or --base), land
# in the squash, then open the `jj-review` zellij layout (managed by
# Nix, includes the zjstatus bar) with hx (left) and prr (right).
#
# Design:
# - The prr ref (full GitHub URI) is written to /tmp/jj-review-ref;
#   the `jj-review` zellij layout reads it via
#   `prr edit $(cat /tmp/jj-review-ref)`.
# - Pane commands are `sh -c "hx; nu"` and
#   `sh -c "prr edit ...; nu"`. zellij panes are exec-style (command
#   = argc, args = argv), so chaining has to happen inside sh. After
#   hx/prr exits, nu runs interactively — no dead pane.
# - sh inherits the zellij session env (PATH, NIX_LD_LIBRARY_PATH,
#   GITHUB_TOKEN, etc.). No manual env wiring.
# - `zellij --layout jj-review` creates a new tab when already in a
#   session (preserving the existing layout) and starts a new session
#   otherwise. No branch on $env.ZELLIJ needed.
def main [
    url: string
    --base: string       # jj revset to squash onto (default: PR's target branch)
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

    # Default to the PR's target branch (baseRefName), not trunk().
    # This handles PRs into feature branches correctly — the squash
    # sits on the PR's actual target, and the revset
    # baseRefOid..headRefOid (ancestors(head) & ~ancestors(base))
    # gives just the PR's commits regardless of whether the base
    # branch has moved past the original fork point.
    let base_rev = (if $base == null { $meta.baseRefName } else { $base })

    print $"Fetching PR #($meta.number)..."
    fetch-pr $meta

    print $"Squashing onto ($base_rev)..."
    jj new $base_rev
    jj squash --ignore-immutable -m $"Squashed PR #($meta.number) for review.\njj-review: head=($meta.headRefOid) base=($meta.baseRefOid)" -t @ -f $"($meta.baseRefOid)..($meta.headRefOid)"

    print $"Fetching prr file..."
    try { prr get $url } catch { print "Warning: prr get failed (no token?)" }

    # Write the prr ref (full GitHub URI) for the static zellij layout
    # to pick up via `prr edit $(cat /tmp/jj-review-ref)`.
    $url | save --force /tmp/jj-review-ref

    print "Opening zellij tab for review..."
    zellij --layout jj-review
}
