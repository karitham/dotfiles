#!/usr/bin/env -S nu --no-config-file
# jj-review: PR review workflow with jj, prr, and hx.
# Requires: jj, gh, git, prr, hx (helix).

# Squash the PR commits onto the target branch in a new jj change.
def squash-review-change [meta: record, base_rev: string]: nothing -> nothing {
    jj new $base_rev
    jj squash --ignore-immutable -m $"Squashed PR #($meta.number) for review.\njj-review: head=($meta.headRefOid) base=($meta.baseRefOid)" -t @ -f $"($meta.baseRefOid)..($meta.headRefOid)"
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
    --base: string       # jj revset to squash onto (default: PR's target branch)
]: nothing -> nothing {

    # Phase 1: Run three independent network operations in parallel.
    # - gh pr view:  PR metadata (needed for squash, cross-repo fetch)
    # - prr get:     review file download (needed for helix)
    # - jj git fetch origin: base remote refs (needed for squash)
    # All three depend only on the input URL, not on each other.
    # --keep-order pins results to input order: $p.0=gh, $p.1=prr, $p.2=fetch.
    print $"Fetching PR metadata, review file, and origin refs for ($url)..."
    let p = (
        [gh prr fetch]
        | par-each --keep-order { |tag|
            match $tag {
                "gh"    => { do { gh pr view $url --json "url,number,title,baseRefName,headRefName,isCrossRepository,headRepository,headRepositoryOwner,headRefOid,baseRefOid" } | complete }
                "prr"   => { do { prr get $url } | complete }
                "fetch" => { do { jj git fetch --remote origin } | complete }
                _ => { error make {msg: $"unknown tag: ($tag)"} }
            }
        }
    )

    let gh_result = $p.0
    if $gh_result.exit_code != 0 {
        error make {msg: $"gh pr view failed: ($gh_result.stderr)"}
    }
    let meta = $gh_result.stdout | str trim | from json
    let base_rev = (if $base == null { $meta.baseRefName } else { $base })

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

    print $"PR #($meta.number): squashing onto ($base_rev)..."
    squash-review-change $meta $base_rev

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
}
