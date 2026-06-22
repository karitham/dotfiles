#!/usr/bin/env -S nu --no-config-file
# jj-review: PR review workflow with jj, prr, and hx.
# Requires: jj, gh, git, prr, hx (helix).

# Squash the PR commits onto the target branch in a new jj change. Returns
# the change-ids of the previous working copy and the new review change so
# the caller can restore @ after helix closes.
#
# The original PR commits and their bookmarks are preserved by duplicating
# the source range first and squashing only the duplicates: a plain
# `jj squash` of the source range would abandon the originals and, per the
# jj docs, "When a commit has been abandoned, all associated bookmarks will
# be deleted." The duplicates have no bookmarks, so abandoning them is
# harmless.
def squash-review-change [meta: record, base_rev: string, head_rev: string]: nothing -> record<prev_wc: string, review_wc: string> {
    # Capture the user's current working copy so we can restore it after review.
    let prev_wc = jj log -r @ -T change_id --no-graph --limit 1 | str trim

    # Create a new empty working copy on top of base.
    jj new $base_rev

    # Duplicate the PR commits and insert them between base and @. Originals
    # (with their bookmarks) stay intact; the duplicates have no bookmarks.
    jj duplicate -B @ -r $"($base_rev)..($head_rev)"

    # Squash the duplicates into @. They get abandoned, but since they had
    # no bookmarks nothing is lost.
    #
    # --ignore-immutable is required because the duplicates inherit the
    # original PR authors and therefore match a strict `immutable_heads`
    # revset like `(trunk().. & ~mine())`. The originals (with their
    # bookmarks) are still untouched — only the temporary duplicates we
    # just created are rewritten.
    jj squash --ignore-immutable -m $"Squashed PR #($meta.number) for review.\njj-review: head=($meta.headRefOid) base=($meta.baseRefOid)" -t @ -f $"($base_rev)..@-"

    # Capture the new review change-id so the caller can print it for the user.
    let review_wc = jj log -r @ -T change_id --no-graph --limit 1 | str trim

    {prev_wc: $prev_wc, review_wc: $review_wc}
}

# Discover an existing review's path by opening it in a no-op editor.
# More reliable than reconstructing the path because prr uses its own
# configured workdir and local config.
def existing-prr-path [url: string]: nothing -> string {
    let edit = do { prr edit $url } | complete
    if $edit.exit_code != 0 {
        return (error make {msg: $"prr edit failed: ($edit.stderr)"})
    }
    let path = $edit.stdout | str trim
    if $path == "" {
        return (error make {msg: "prr edit returned an empty path"})
    }
    $path
}

# Return the path to the prr review file, downloading it if necessary.
# If the review already exists with unsubmitted changes, re-use the existing
# file instead of failing.
def fetch-prr-path [url: string]: nothing -> string {
    let get = do { prr get $url } | complete
    if $get.exit_code == 0 {
        let path = $get.stdout | str trim
        if $path != "" {
            return $path
        }
    }

    if ($get.stderr | str contains "unsubmitted changes") {
        return (existing-prr-path $url)
    }

    return (error make {msg: $"prr get failed: ($get.stderr)"})
}

# Return the jj workspace root so helix can run from the repo regardless of
# where this script was invoked.
def jj-repo-root []: nothing -> string {
    let root = do { jj root } | complete
    if $root.exit_code != 0 {
        error make {msg: $"jj root failed: ($root.stderr)"}
    }
    $root.stdout | str trim
}

# Pick the first modified or added file from the squashed PR for the left
# pane. Deleted files are skipped because they cannot be opened as review
# context. Returns { path, temp } where temp is true for fallback empty files.
def left-pane-file []: nothing -> record<path: string, temp: bool> {
    let summary = do { jj diff --summary } | complete
    if $summary.exit_code != 0 {
        return {
            path: (mktemp)
            temp: true
        }
    }

    let files = ($summary.stdout
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

# Open helix with a changed file on the left and the review file on the right.
# Uses the repo root as the working directory so relative paths from jj diff
# resolve correctly and the file picker starts in the repo.
def open-helix-review [prr_file: string]: nothing -> nothing {
    if not ($prr_file | path exists) {
        error make {msg: $"prr review file not found: ($prr_file)"}
    }

    let left = (left-pane-file)
    let repo_root = (jj-repo-root)
    hx --working-dir $repo_root --vsplit $left.path $prr_file
    if $left.temp {
        rm $left.path
    }
}

def main [
    url: string
    --base: string       # jj revset to squash onto (default: <PR target branch>@<--remote>)
    --remote: string = "origin"  # remote to use for branch refs (default: origin)
]: nothing -> nothing {

    # Phase 1: Run three independent network operations in parallel.
    # - gh pr view:  PR metadata (needed for squash, cross-repo fetch)
    # - prr get:     review file download (needed for helix)
    # - jj git fetch --remote: base remote refs (needed for squash)
    # All three depend only on the input URL, not on each other.
    # --keep-order pins results to input order: $p.0=gh, $p.1=prr, $p.2=fetch.
    print $"Fetching PR metadata, review file, and ($remote) refs for ($url)..."
    let p = (
        ["gh" "prr" $remote]
        | par-each --keep-order { |tag|
            if $tag == "gh" {
                do { gh pr view $url --json "url,number,title,baseRefName,headRefName,isCrossRepository,headRepository,headRepositoryOwner,headRefOid,baseRefOid" } | complete
            } else if $tag == "prr" {
                do { prr get $url } | complete
            } else {
                do { jj git fetch --remote $tag } | complete
            }
        }
    )

    let gh_result = $p.0
    if $gh_result.exit_code != 0 {
        error make {msg: $"gh pr view failed: ($gh_result.stderr)"}
    }
    let meta = $gh_result.stdout | str trim | from json

    # Use remote branch refs (e.g. main@origin) so the script works in
    # setups where the relevant branches are only present as remote
    # tracking refs. The head remote is the fork owner for cross-repo
    # PRs; otherwise it matches --remote.
    let base_rev = (if $base == null { $"($meta.baseRefName)@($remote)" } else { $base })
    let head_remote = (
        if $meta.isCrossRepository { $meta.headRepositoryOwner.login } else { $remote }
    )
    let head_rev = $"($meta.headRefName)@($head_remote)"

    # Cross-repo fetch if needed (depends on metadata from gh).
    if $meta.isCrossRepository {
        let owner = $meta.headRepositoryOwner.login
        let repo_url = $meta.headRepository.url
        let existing = git remote | lines
        if not ($owner in $existing) {
            jj git remote add $owner $repo_url
        }
        print $"Fetching fork ($owner)..."
        jj git fetch --remote $owner
    }

    print $"PR #($meta.number): squashing ($base_rev)..($head_rev)..."
    let ids = (squash-review-change $meta $base_rev $head_rev)

    # Process prr result. If prr get failed with the input URL, retry with
    # the canonical URL from gh metadata (handles non-URL inputs like PR
    # numbers that gh accepts but prr does not).
    let prr_result = $p.1
    let prr_file = (
        if $prr_result.exit_code == 0 and ($prr_result.stdout | str trim) != "" {
            $prr_result.stdout | str trim
        } else if ($prr_result.stderr | str contains "unsubmitted changes") {
            existing-prr-path $url
        } else if $meta.url != $url {
            fetch-prr-path $meta.url
        } else {
            error make {msg: $"prr get failed: ($prr_result.stderr)"}
        }
    )

    print "Opening helix for review..."
    open-helix-review $prr_file

    # Restore the user's working copy so the script is idempotent across
    # runs. The review change remains in the log for later reference.
    jj edit $ids.prev_wc
    print $"Review change: ($ids.review_wc). Run 'jj edit ($ids.review_wc)' to revisit."
}
