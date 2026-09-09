# gh-prc — list PR reviews and their inline comments via `gh`.
#
# Installed as `gh-prc`, so the gh CLI picks it up as an extension: `gh prc`.
# The PR is selected by explicit reference (URL, owner/repo#123, or number),
# or inferred from the closest bookmarked ancestor of @ via jj.
#
# Comments print as `path:line` (relative to cwd when possible) so the
# location token can be opened directly in helix: `hx path/to/file.rs:42`.
#
# Resolved threads are hidden unless --all; review states can be filtered
# with --state approved,changes-requested.

# ---------- PR reference resolution ----------

# Run an external command (given as a closure so gh's own flags aren't
# consumed by this command's parser); error with its stderr on failure; parse
# JSON stdout.
def run-json [ctx: closure]: nothing -> any {
    let out = do $ctx | complete
    if $out.exit_code != 0 {
        error make {msg: $"($out.stderr | str trim)"}
    }
    $out.stdout | from json
}

def current-repo [] {
    run-json { gh repo view --json nameWithOwner }
    | get nameWithOwner
    | split row "/"
}

def parse-pr-ref [ref: string] {
    let url = (
        $ref
        | parse -r 'github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/pull/(?<number>\d+)'
    )
    if not ($url | is-empty) {
        return {
            owner: $url.owner.0
            repo: $url.repo.0
            number: ($url.number.0 | into int)
        }
    }
    let slug = $ref | parse -r '^(?<owner>[^/\s#]+)/(?<repo>[^/\s#]+)#?(?<number>\d+)$'
    if not ($slug | is-empty) {
        return {
            owner: $slug.owner.0
            repo: $slug.repo.0
            number: ($slug.number.0 | into int)
        }
    }
    let slash = $ref | parse -r '^(?<owner>[^/\s#]+)/(?<repo>[^/\s#]+)/(?<number>\d+)$'
    if not ($slash | is-empty) {
        return {
            owner: $slash.owner.0
            repo: $slash.repo.0
            number: ($slash.number.0 | into int)
        }
    }
    let num = $ref | str trim -c "#" | parse -r '^(?<number>\d+)$'
    if not ($num | is-empty) {
        let parts = (current-repo)
        return {
            owner: $parts.0
            repo: $parts.1
            number: ($num.number.0 | into int)
        }
    }
    error make {msg: $"can't parse PR reference '($ref)': expected a URL, owner/repo#123, owner/repo/123, or a number"}
}

def detect-branch []: nothing -> list<string> {

    # Closest bookmarked ancestor of @. jj's `bookmarks` template renders every
    # bookmark on the commit (local ones with sync markers `*`/`+`/`~`/`??`,
    # plus remote-tracking `name@remote` entries); normalize to plain local
    # names, git-matching bookmark first. Falls back to the colocated git
    # branch when jj has nothing bookmarked (or isn't available).
    let git = (
        git symbolic-ref --short HEAD
        | complete
        | get stdout
        | str trim
    )
    let jj = (
        jj log -r "latest(ancestors(@) & bookmarks(), 1)" --no-graph -T "bookmarks"
        | complete
    )
    let bookmarks = (
        $jj.stdout
        | str trim
        | split row " "
        | each {|t|
            $t
            | str replace -r '@[^@]+$' ''
            | str replace -r '[*+~?]+$' ''
        }
        | where {|t| $t != "" and not ($t | str contains "@") }
        | uniq
    )
    if $jj.exit_code == 0 and ($bookmarks | is-not-empty) {
        return ($bookmarks | sort-by {|b| $b != $git })
    }
    if $git == "" {
        error make {msg: "could not detect a branch via jj or git"}
    }
    [$git]
}

def resolve-ref [pr?: string] {
    if ($pr | is-empty) {
        let candidates = (detect-branch)
        # Several bookmarks may share the matched commit; use the first one
        # with an OPEN PR (git-matching bookmark tried first). gh pr view
        # happily resolves merged/closed PRs, so require OPEN explicitly.
        # Failures that aren't simply "branch has no PR" (auth, network) are
        # kept as a hint for the final error.
        mut failures = []
        for branch in $candidates {
            let v = (
                try {
                    run-json { gh pr view $branch --json number,url,state }
                } catch {|err| { error: ($err.msg | default "") } }
            )
            if ($v.error? | is-empty) {
                if $v.state == "OPEN" {
                    return (parse-pr-ref $v.url)
                }
            } else if not ($v.error | str contains "no pull requests found") {
                $failures = ($failures | append $v.error)
            }
        }
        let hint = (
            if ($failures | is-not-empty) { $" - ($failures | str join '; ')" } else { "" }
        )
        error make {msg: $"no open PR found for branches: ($candidates | str join ', ')($hint)"}
    }
    parse-pr-ref $pr
}

# ---------- GraphQL ----------

def fetch-pr [owner: string, repo: string, number: int]: nothing -> any {
    let query = "query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$number){number title state url baseRefName headRefName reviews(last:100){nodes{databaseId state author{login} submittedAt body comments(first:100){nodes{databaseId path line originalLine outdated createdAt author{login} body replyTo{databaseId} pullRequestReview{databaseId}}}}} reviewThreads(first:100){nodes{isResolved comments(first:100){nodes{databaseId}}}}}}}"
    run-json { gh api graphql -f $"query=($query)" -F $"owner=($owner)" -F $"repo=($repo)" -F $"number=($number)" }
    | get data.repository.pullRequest
}

# ---------- display ----------

def state-color [state: string]: nothing -> string {
    match $state {
        "APPROVED" => (ansi green)
        "CHANGES_REQUESTED" => (ansi red)
        _ => (ansi yellow)
    }
}

def indent [text: string, pad: int]: nothing -> string {
    let padstr = " " | fill -w $pad
    $text | lines | each {|line| $"($padstr)($line)" } | str join "\n"
}

def comment-loc [c: record, root: string, cwd: string]: nothing -> string {
    let line = $c.line? | default $c.originalLine?
    # Prefer a path that opens from here: raw repo-relative path if the file
    # exists in cwd, then anchored to the workspace root (for subdirectory
    # checkouts), else the raw path (e.g. reviewing a different repo).
    let loc = (if ($c.path | path exists) {
        $c.path
    } else if $root != "" and (($root | path join $c.path) | path exists) {
        let abs = $root | path join $c.path
        do -i { $abs | path relative-to $cwd } | default $abs
    } else {
        $c.path
    })
    if $line == null { $loc } else { $"($loc):($line)" }
}

# Shared comment visibility filter: --outdated, --resolved, and hide-resolved
# (unless --all). Applied uniformly to root comments and replies.
def visible [
    c: record
    outdated: bool
    resolved: bool
    all: bool
] {
    if $outdated and not $c.outdated { return false }
    if $resolved { $c.resolved } else if not $all { not $c.resolved } else { true }
}

# Print one comment (or reply) as `path:line · author (tags)` plus its full body.
# `resolved` is precomputed from the thread map and attached to the record.
def print-comment [
    c: record
    pad: int
    root: string
    cwd: string
]: nothing -> nothing {
    let tags = ([
        (if $c.outdated { "(outdated)" } else { "" })
        (if $c.resolved { "(resolved)" } else { "" })
    ] | str join " " | str trim)
    let tag_str = (if $tags == "" { "" } else { $" (ansi d)($tags)(ansi rst)" })
    let author = $c.author?.login? | default "ghost"
    let loc = (comment-loc $c $root $cwd)
    let lead = " " | fill -w $pad

    print $"($lead)(ansi cyan)($loc)(ansi rst)(ansi d) · ($author)($tag_str)(ansi rst)"
    if ($c.body? | default "" | str trim) != "" {
        print (indent $c.body ($pad + 4))
    }
}

def format-states [wanted?: string]: nothing -> list<string> {
    if ($wanted | is-empty) { return [] }
    let valid = ["APPROVED" "CHANGES_REQUESTED" "COMMENTED" "PENDING" "DISMISSED"]
    let parsed = ($wanted
        | split row ","
        | each {|s| $s | str trim | str uppercase | str replace -a "-" "_" | str replace -a " " "_" })
    let known = $parsed | where {|s| $s in $valid }
    if ($known | is-empty) {
        error make {msg: $"no valid review states in '($wanted)' - valid: approved, changes-requested, commented, pending, dismissed"}
    }
    let unknown = $parsed | where {|s| $s not-in $valid }
    if ($unknown | is-not-empty) {
        print -e $"gh-prc: ignoring unknown states: ($unknown | str join ', ')"
    }
    $known
}

def main [
    ...pr: string # PR: URL, owner/repo#123, owner/repo/123, #123, or plain number; inferred via jj when omitted
    --state (-s): string # Comma-separated review states to keep (APPROVED, CHANGES_REQUESTED, COMMENTED, PENDING, DISMISSED)
    --all # Include comments in resolved threads
    --resolved # Only comments in resolved threads
    --outdated # Only outdated comments
] {
    let ref = (
        if ($pr | is-empty) { resolve-ref } else { resolve-ref ($pr | str join " ") }
    )
    let data = (fetch-pr $ref.owner $ref.repo $ref.number)
    let cwd = (pwd)
    let root = (
        jj workspace root
        | complete
        | get stdout
        | str trim
    )

    let resolved_ids = ($data.reviewThreads.nodes
        | where isResolved
        | each {|t| $t.comments.nodes | get -o databaseId | default [] }
        | flatten)

    # Attach the thread's resolved flag to every comment once.
    let all_comments = ($data.reviews.nodes
        | each {|r| $r.comments.nodes }
        | flatten
        | insert resolved {|c| $c.databaseId in $resolved_ids })

    # Replies may be submitted as their own review records; regroup them under
    # the root comment of their thread so threads render as a tree.
    let replies_by_root = ($all_comments
        | where {|c| $c.replyTo?.databaseId? != null }
        | group-by {|c| $c.replyTo.databaseId })

    # ...and to each review's own comments (replies included; they are skipped
    # at render time when their root lives in another review).
    let comments_by_review = $all_comments | group-by {|c| $c.pullRequestReview.databaseId }

    let wanted = (format-states $state)

    let reviews = ($data.reviews.nodes
        | where {|r| ($wanted | is-empty) or ($r.state in $wanted) }
        | each {|r|
            {
                id: $r.databaseId
                state: $r.state
                author: ($r.author?.login? | default "ghost")
                # "9999" sorts unsubmitted/pending reviews last
                date: ($r.submittedAt? | default "9999" | str replace "T" " ")
                body: ($r.body? | default "")
                comments: ($comments_by_review
                    | get -o ($r.databaseId | into string)
                    | default [])
            }
        }
        | sort-by date)

    # Rendering is wrapped in try so a closed pipe (e.g. `gh prc ... | head`)
    # exits quietly instead of spraying broken-pipe errors.
    try {
        print $"(ansi bo)#($data.number) ($data.title) [($data.state)] ($data.baseRefName) <- ($data.headRefName)(ansi rst)"
        print $"($data.url)"

        if ($reviews | is-empty) {
            print "(no reviews)"
        } else {
            for r in $reviews {
                let color = (state-color $r.state)
                let date = $r.date | str substring 0..<16

                # Root comments; replies (from any review) render nested below.
                let roots_all = $r.comments | where {|c| $c.replyTo?.databaseId? == null }
                let loose = $r.comments | where {|c| $c.replyTo?.databaseId? != null }
                let roots = $roots_all | where {|c| visible $c $outdated $resolved $all }

                # A review that is nothing but replies to another review's
                # threads adds no information of its own — skip it entirely.
                # Reviews with no comments at all still show (approvals etc.).
                if ($roots_all | is-empty) and ($loose | is-not-empty) and (($r.body | str trim) == "") {
                    continue
                }

                print $"(ansi d)──(ansi rst) ($color)($r.state)(ansi rst) (ansi bo)($r.author)(ansi rst) (ansi d)($date) · review ($r.id)(ansi rst)"

                if ($r.body | str trim) != "" {
                    print (indent $r.body 2)
                }

                if ($roots | is-empty) {
                    # Under --outdated, a current root may still hold outdated
                    # replies; surface them anchored to the hidden root.
                    if $outdated {
                        for c in $roots_all {
                            let children = ($replies_by_root
                                | get -o ($c.databaseId | into string)
                                | default []
                                | where {|rep| visible $rep $outdated $resolved $all }
                                | sort-by createdAt)
                            if ($children | is-not-empty) {
                                let anchor = (comment-loc $c $root $cwd)
                                let note = "(outdated replies under hidden root"
                                print $"  (ansi d)($note) ($anchor))(ansi rst)"
                                for rep in $children {
                                    print-comment $rep 4 $root $cwd
                                }
                            }
                        }
                    } else {
                        let none = "(no inline comments)"
                        print $"  (ansi d)($none)(ansi rst)"
                    }
                } else {
                    for c in $roots {
                        print-comment $c 2 $root $cwd
                        let children = ($replies_by_root
                            | get -o ($c.databaseId | into string)
                            | default []
                            | where {|rep| visible $rep $outdated $resolved $all }
                            | sort-by createdAt)
                        for rep in $children {
                            print-comment $rep 4 $root $cwd
                        }
                    }
                }
                print ""
            }
        }
    }
}
