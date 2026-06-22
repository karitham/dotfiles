#!/usr/bin/env -S nu --no-config-file
#
# jj-review: PR review workflow with jj, prr, and hx.
# Requires: jj, gh, git, prr, hx (helix).
#
# The review change remains in the log after the script exits; revisit
# it with `jj edit <review-change-id>`.

# run-capture executes a closure and returns its {exit_code, stdout, stderr} record.
def run-capture [code: closure]: nothing -> record {
    do $code | complete
}

# run-or-error executes a closure, returning trimmed stdout or raising an
# error annotated with label and the command's stderr.
def run-or-error [label: string, code: closure]: nothing -> string {
    let result = (run-capture $code)
    if $result.exit_code != 0 {
        return (error make {msg: $"($label) failed: ($result.stderr | str trim)"})
    }
    $result.stdout | str trim
}

# PR_FIELDS is the JSON contract with `gh pr view`. Keep narrow.
const PR_FIELDS = [
    "url"
    "number"
    "title"
    "baseRefName"
    "headRefName"
    "isCrossRepository"
    "headRepository"
    "headRepositoryOwner"
    "headRefOid"
    "baseRefOid"
]

# fetch-pr-metadata fetches PR metadata via `gh pr view` and parses it into a record.
def fetch-pr-metadata [url: string]: nothing -> record {
    run-or-error "gh pr view" {
        gh pr view $url --json ($PR_FIELDS | str join ",")
    } | from json
}

# derive-pr-revs returns the base/head revsets for a PR. base_override
# of null falls back to `<baseRefName>@<remote>`. For cross-repo PRs the
# head uses the fork owner's name, not remote.
def derive-pr-revs [meta: record, base_override, remote: string]: nothing -> record<base_rev: string, head_rev: string, head_remote: string> {
    let base_rev = (
        if $base_override == null {
            $"($meta.baseRefName)@($remote)"
        } else {
            $"($base_override)"
        }
    )
    let head_remote = (
        if $meta.isCrossRepository { $meta.headRepositoryOwner.login } else { $remote }
    )
    let head_rev = $"($meta.headRefName)@($head_remote)"

    {base_rev: $base_rev, head_rev: $head_rev, head_remote: $head_remote}
}

# ensure-fork-fetched adds the fork as a remote and fetches it. No-op for same-repo PRs.
def ensure-fork-fetched [meta: record]: nothing -> nothing {
    if not $meta.isCrossRepository {
        return
    }
    let owner = $meta.headRepositoryOwner.login
    let repo_url = $meta.headRepository.url
    let existing = git remote | lines
    if not ($owner in $existing) {
        run-or-error "jj git remote add" { jj git remote add $owner $repo_url } | ignore
    }
    print $"Fetching fork ($owner)..."
    run-or-error "jj git fetch" { jj git fetch --remote $owner } | ignore
}

# current-change-id returns the change-id of @ as a short string.
def current-change-id []: nothing -> string {
    jj log -r @ -T change_id --no-graph --limit 1 | str trim
}

# squash-review-change duplicates the PR range and squashes the duplicates
# onto base in a new change. The duplicates have no bookmarks, so abandoning
# them is harmless; the originals (with their bookmarks) stay intact.
# --ignore-immutable is required because the duplicates inherit the original
# PR authors and match strict `immutable_heads` revsets like `(trunk().. & ~mine())`.
def squash-review-change [meta: record, base_rev: string, head_rev: string]: nothing -> record<prev_wc: string, review_wc: string> {
    let prev_wc = (current-change-id)

    jj new $base_rev
    jj duplicate -B @ -r $"($base_rev)..($head_rev)"
    jj squash --ignore-immutable -m $"Squashed PR #($meta.number) for review.\njj-review: head=($meta.headRefOid) base=($meta.baseRefOid)" -t @ -f $"($base_rev)..@-"

    {
        prev_wc: $prev_wc
        review_wc: (current-change-id)
    }
}

# prr-edit-path discovers the path of an existing review via `prr edit`,
# which opens the configured no-op editor.
def prr-edit-path [url: string]: nothing -> string {
    let result = (run-capture { prr edit $url })
    if $result.exit_code != 0 {
        return (error make {msg: $"prr edit failed: ($result.stderr | str trim)"})
    }
    let path = $result.stdout | str trim
    if $path == "" {
        return (error make {msg: "prr edit returned an empty path"})
    }
    $path
}

# prr-get-or-existing runs `prr get`, falling back to `prr edit` for the
# unsubmitted-changes case.
def prr-get-or-existing [url: string]: nothing -> string {
    let result = (run-capture { prr get $url })
    if $result.exit_code == 0 and ($result.stdout | str trim) != "" {
        return ($result.stdout | str trim)
    }
    if ($result.stderr | str contains "unsubmitted changes") {
        return (prr-edit-path $url)
    }
    return (error make {msg: $"prr get failed: ($result.stderr | str trim)"})
}

# resolve-prr-path returns the path to the prr review file, retrying
# against meta.url when the input differs (e.g. a PR number).
def resolve-prr-path [url: string, meta: record, prr_result: record]: nothing -> string {
    if $prr_result.exit_code == 0 and ($prr_result.stdout | str trim) != "" {
        return ($prr_result.stdout | str trim)
    }
    if ($prr_result.stderr | str contains "unsubmitted changes") {
        return (prr-edit-path $url)
    }
    if $meta.url != $url {
        return (prr-get-or-existing $meta.url)
    }
    return (error make {msg: $"prr get failed: ($prr_result.stderr | str trim)"})
}

# left-pane-file returns the first modified/added file from the squashed
# diff, or a temp file if none exists. The caller cleans up temp files
# (see temp: true).
def left-pane-file []: nothing -> record<path: string, temp: bool> {
    let summary = (run-capture { jj diff --summary })
    if $summary.exit_code != 0 {
        return {
            path: (mktemp)
            temp: true
        }
    }
    let files = (
        $summary.stdout
        | lines
        | parse "{status} {path}"
        | where status in [M A]
    )
    if ($files | is-empty) {
        return {
            path: (mktemp)
            temp: true
        }
    }
    {path: $files.0.path, temp: false}
}

# jj-repo-root returns the jj workspace root.
def jj-repo-root []: nothing -> string {
    run-or-error "jj root" { jj root }
}

# open-helix-review opens helix with the left pane on a changed file (or a
# temp file) and the right pane on the prr review file. The working directory
# is the repo root so relative paths from `jj diff` resolve.
def open-helix-review [prr_file: string]: nothing -> nothing {
    if not ($prr_file | path exists) {
        return (error make {msg: $"prr review file not found: ($prr_file)"})
    }
    let left = (left-pane-file)
    let repo_root = (jj-repo-root)
    try {
        hx --working-dir $repo_root --vsplit $left.path $prr_file
    } finally {
        if $left.temp {
            rm $left.path
        }
    }
}

def main [
    url: string
    --base: string       # jj revset to squash onto (default: <PR target branch>@<--remote>)
    --remote: string = "origin"  # remote to use for base/head branch refs
]: nothing -> nothing {
    print $"Fetching PR metadata, review file, and ($remote) refs for ($url)..."
    let p = (
        [gh prr fetch]
        | par-each --keep-order { |tag|
            match $tag {
                gh => (run-capture { gh pr view $url --json ($PR_FIELDS | str join ",") }),
                prr => (run-capture { prr get $url }),
                _ => (run-capture { jj git fetch --remote $remote }),
            }
        }
    )

    if $p.0.exit_code != 0 {
        return (error make {msg: $"gh pr view failed: ($p.0.stderr | str trim)"})
    }
    let meta = $p.0.stdout | str trim | from json
    let revs = (derive-pr-revs $meta $base $remote)

    ensure-fork-fetched $meta

    print $"PR #($meta.number): squashing ($revs.base_rev)..($revs.head_rev)..."
    let ids = (squash-review-change $meta $revs.base_rev $revs.head_rev)

    let prr_file = (resolve-prr-path $url $meta $p.1)

    print "Opening helix for review..."
    open-helix-review $prr_file

    jj edit $ids.prev_wc
    print $"Review change: ($ids.review_wc). Run 'jj edit ($ids.review_wc)' to revisit."
}
