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
#
# Threads are identifiable by comment id: roots print `thread <id>` (their own
# comment id doubles as the thread id), replies print `#<id> (thread <id>)`.
# Pass any visible id to --thread to show just that thread (implies --all).

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

# Does thread `root_id` (root + its replies) contain comment `wanted`?
# Lets --thread accept a root id or any reply id in the thread.
def thread-contains [root_id: int, wanted: int, replies_by_root: record]: nothing -> bool {
    if $root_id == $wanted { return true }
    $replies_by_root
    | get -o ($root_id | into string)
    | default []
    | any {|rep| $rep.databaseId == $wanted }
}

# Print one comment (or reply) as `path:line · author (tags) · thread <id>`
# plus its full body. Roots show `thread <id>`; replies show `#<id>` with
# their thread, so any visible id can be passed to --thread.
# `resolved` is precomputed from the thread map and attached to the record.
def print-comment [
    c: record
    pad: int
    root: string
    cwd: string
    thread: int
    is_root: bool
]: nothing -> nothing {
    let tags = ([
        (if $c.outdated { "(outdated)" } else { "" })
        (if $c.resolved { "(resolved)" } else { "" })
    ] | where {|s| $s != "" } | str join " ")
    let id_label = if $is_root { $"thread ($thread)" } else { "#" ++ ($c.databaseId | into string) ++ " (thread " ++ ($thread | into string) ++ ")" }
    let suffix = [$tags $id_label] | where {|s| $s != "" } | str join " "
    let author = $c.author?.login? | default "ghost"
    let loc = (comment-loc $c $root $cwd)
    let lead = " " | fill -w $pad

    print $"($lead)(ansi cyan)($loc)(ansi rst)(ansi d) · ($author) ($suffix)(ansi rst)"
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
    --thread (-t): int # Only the thread containing comment <id> (a root id or any reply id in it; implies --all)
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

    # --thread selects one thread by any comment id in it; it implies --all
    # so a resolved thread still shows (explicit --resolved/--outdated still
    # narrow further).
    let show_all = $all or ($thread != null)
    # Existence is independent of visibility: an id either names a thread or
    # it doesn't, regardless of --state/--resolved/--outdated hiding it.
    let thread_exists = if $thread == null { true } else { $all_comments | any {|c| $c.databaseId == $thread } }

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
            mut shown = 0
            for r in $reviews {
                let color = (state-color $r.state)
                let date = $r.date | str substring 0..<16

                # Root comments; replies (from any review) render nested below.
                let roots_all = $r.comments | where {|c| $c.replyTo?.databaseId? == null }
                let loose = $r.comments | where {|c| $c.replyTo?.databaseId? != null }
                let roots = ($roots_all
                    | where {|c| visible $c $outdated $resolved $show_all }
                    | where {|c| if $thread == null { true } else { thread-contains $c.databaseId $thread $replies_by_root } })

                # A review that is nothing but replies to another review's
                # threads adds no information of its own — skip it entirely.
                # Reviews with no comments at all still show (approvals etc.).
                if ($roots_all | is-empty) and ($loose | is-not-empty) and (($r.body | str trim) == "") {
                    continue
                }

                # With --thread, reviews outside the wanted thread are noise —
                # skip them instead of printing "(no inline comments)".
                if $thread != null and ($roots | is-empty) {
                    if not $outdated {
                        continue
                    }
                    let has_kids = ($roots_all
                        | where {|c| thread-contains $c.databaseId $thread $replies_by_root }
                        | any {|c| ($replies_by_root
                            | get -o ($c.databaseId | into string)
                            | default []
                            | where {|rep| visible $rep $outdated $resolved $show_all }
                            | is-not-empty) })
                    if not $has_kids {
                        continue
                    }
                }

                $shown += 1
                print $"(ansi d)──(ansi rst) ($color)($r.state)(ansi rst) (ansi bo)($r.author)(ansi rst) (ansi d)($date) · review ($r.id)(ansi rst)"

                if ($r.body | str trim) != "" {
                    print (indent $r.body 2)
                }

                if ($roots | is-empty) {
                    # Under --outdated, a current root may still hold outdated
                    # replies; surface them anchored to the hidden root.
                    if $outdated {
                        for c in (
                            $roots_all
                            | where {|c| if $thread == null { true } else { thread-contains $c.databaseId $thread $replies_by_root } }
                        ) {
                            let children = ($replies_by_root
                                | get -o ($c.databaseId | into string)
                                | default []
                                | where {|rep| visible $rep $outdated $resolved $show_all }
                                | sort-by createdAt)
                            if ($children | is-not-empty) {
                                let anchor = (comment-loc $c $root $cwd)
                                let note = "(outdated replies under hidden root"
                                print $"  (ansi d)($note) ($anchor))(ansi rst)"
                                for rep in $children {
                                    print-comment $rep 4 $root $cwd $c.databaseId false
                                }
                            }
                        }
                    } else {
                        let none = "(no inline comments)"
                        print $"  (ansi d)($none)(ansi rst)"
                    }
                } else {
                    for c in $roots {
                        print-comment $c 2 $root $cwd $c.databaseId true
                        let children = ($replies_by_root
                            | get -o ($c.databaseId | into string)
                            | default []
                            | where {|rep| visible $rep $outdated $resolved $show_all }
                            | sort-by createdAt)
                        for rep in $children {
                            print-comment $rep 4 $root $cwd $c.databaseId false
                        }
                    }
                }
                print ""
            }
            if $thread != null and $shown == 0 {
                if $thread_exists {
                    print $"thread ($thread) hidden by filters"
                } else {
                    print $"no thread matches ($thread)"
                }
            }
        }
    }
}
