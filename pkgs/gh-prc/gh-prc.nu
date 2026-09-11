# gh-prc — list PR reviews and their inline comments via `gh prc`.
#
# PR: explicit reference (URL, owner/repo#123, or number), or inferred from the
# closest bookmarked ancestor of @ via jj. Comments print as `path:line` so
# the location opens directly in helix. Roots print `thread <id>`, replies
# `#<id> (thread <id>)`; --thread shows one thread by any visible id.
# Resolved threads are hidden unless --all.

def run-json [ctx: closure]: nothing -> any {

    # Closure so gh's own flags aren't consumed by this command's parser.
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

    # Bookmarks on the closest bookmarked ancestor of @, normalized to plain
    # local names (git match first); falls back to the git branch.
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
        # First branch with an OPEN PR; gh also resolves merged/closed ones.
        # Non-"no PR" failures are kept as a hint for the final error.
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

def fetch-pr [owner: string, repo: string, number: int]: nothing -> any {
    let query = "query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$number){number title state url baseRefName headRefName reviews(last:100){nodes{databaseId state author{login} submittedAt body comments(first:100){nodes{databaseId path line originalLine outdated createdAt author{login} body replyTo{databaseId} pullRequestReview{databaseId}}}}} reviewThreads(first:100){nodes{isResolved comments(first:100){nodes{databaseId}}}}}}}"
    run-json { gh api graphql -f $"query=($query)" -F $"owner=($owner)" -F $"repo=($repo)" -F $"number=($number)" }
    | get data.repository.pullRequest
}

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

# Thread: {id, review, resolved, root, replies}. Built once from raw GraphQL.
def build-threads [comments: list<any>, resolved_ids: list<any>]: nothing -> list<any> {
    let by_root = ($comments
        | where {|c| $c.replyTo?.databaseId? != null }
        | group-by {|c| $c.replyTo.databaseId })
    $comments
    | where {|c| $c.replyTo?.databaseId? == null }
    | each {|c| {
        id: $c.databaseId
        review: $c.pullRequestReview.databaseId
        resolved: ($c.databaseId in $resolved_ids)
        root: $c
        replies: ($by_root | get -o ($c.databaseId | into string) | default [] | sort-by createdAt)
    } }
}

def foreign-reply-count [threads: list<any>, review_id: int]: nothing -> int {
    $threads
    | where {|t| $t.review != $review_id }
    | each {|t| $t.replies | where {|c| $c.pullRequestReview.databaseId == $review_id } }
    | flatten
    | length
}

def thread-has [t: record, id: int]: nothing -> bool {
    $t.id == $id or $id in ($t.replies | each {|c| $c.databaseId })
}

def keep-comment [c: record, t: record, flt: record]: nothing -> bool {
    if $flt.outdated and not $c.outdated { return false }
    if $flt.resolved { $t.resolved } else if not $flt.show_all { not $t.resolved } else { true }
}

def keep-thread [t: record, flt: record]: nothing -> bool {
    if $flt.thread != null and not (thread-has $t $flt.thread) { return false }
    (keep-comment $t.root $t $flt) or (outdated-replies-visible $t $flt)
}

def outdated-replies-visible [t: record, flt: record]: nothing -> bool {
    $flt.outdated and (($t.replies | where {|c| keep-comment $c $t $flt } | is-not-empty))
}

def print-comment [
    c: record
    pad: int
    root: string
    cwd: string
    t: record
]: nothing -> nothing {
    let is_root = $c.databaseId == $t.id
    let tags = ([
        (if $c.outdated { "(outdated)" } else { "" })
        (if $t.resolved { "(resolved)" } else { "" })
    ] | where {|s| $s != "" } | str join " ")
    let id_label = if $is_root { $"thread ($t.id)" } else { "#" ++ ($c.databaseId | into string) ++ " (thread " ++ ($t.id | into string) ++ ")" }
    let suffix = [$tags $id_label] | where {|s| $s != "" } | str join " "
    let author = $c.author?.login? | default "ghost"
    let loc = (comment-loc $c $root $cwd)
    let lead = " " | fill -w $pad

    print $"($lead)(ansi cyan)($loc)(ansi rst)(ansi d) · ($author) ($suffix)(ansi rst)"
    if ($c.body? | default "" | str trim) != "" {
        print (indent $c.body ($pad + 4))
    }
}

def print-thread [
    t: record
    flt: record
    root: string
    cwd: string
]: nothing -> nothing {
    if (keep-comment $t.root $t $flt) {
        print-comment $t.root 2 $root $cwd $t
    } else {
        let anchor = (comment-loc $t.root $root $cwd)
        let note = "(outdated replies under hidden root"
        print $"  (ansi d)($note) ($anchor))(ansi rst)"
    }
    for rep in ($t.replies | where {|c| keep-comment $c $t $flt }) {
        print-comment $rep 4 $root $cwd $t
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

    let flt = {
        outdated: $outdated
        resolved: $resolved
        show_all: ($all or ($thread != null))
        thread: $thread
    }
    let threads = (
        build-threads ($data.reviews.nodes | each {|r| $r.comments.nodes } | flatten) $resolved_ids
    )

    let thread_exists = $flt.thread == null or ($threads | any {|t| thread-has $t $flt.thread })

    let wanted = (format-states $state)

    let reviews = ($data.reviews.nodes
        | where {|r| ($wanted | is-empty) or ($r.state in $wanted) }
        | each {|r|
            let owned = $threads | where {|t| $t.review == $r.databaseId }
            {
                id: $r.databaseId
                state: $r.state
                author: ($r.author?.login? | default "ghost")
                # "9999" sorts unsubmitted/pending reviews last
                date: ($r.submittedAt? | default "9999" | str replace "T" " ")
                body: ($r.body? | default "")
                threads: ($owned | where {|t| keep-thread $t $flt })
                reply_only: (
                    ($owned | is-empty)
                    and (foreign-reply-count $threads $r.databaseId) > 0
                    and (($r.body? | default "" | str trim) == "")
                )
            }
        }
        | where {|r| not $r.reply_only and (($flt.thread == null) or ($r.threads | is-not-empty)) }
        | each {|r| $r | reject reply_only }
        | sort-by date)

    try {

        # closed pipe (e.g. `... | head`) exits quietly
        print $"(ansi bo)#($data.number) ($data.title) [($data.state)] ($data.baseRefName) <- ($data.headRefName)(ansi rst)"
        print $"($data.url)"

        if ($reviews | is-empty) {
            if $flt.thread != null {
                if $thread_exists {
                    print $"thread ($flt.thread) hidden by filters"
                } else {
                    print $"no thread matches ($flt.thread)"
                }
            } else {
                print "(no reviews)"
            }
        } else {
            for r in $reviews {
                let color = (state-color $r.state)
                let date = $r.date | str substring 0..<16

                print $"(ansi d)──(ansi rst) ($color)($r.state)(ansi rst) (ansi bo)($r.author)(ansi rst) (ansi d)($date) · review ($r.id)(ansi rst)"

                if ($r.body | str trim) != "" {
                    print (indent $r.body 2)
                }

                if ($r.threads | is-empty) {
                    if not $flt.outdated {
                        let none = "(no inline comments)"
                        print $"  (ansi d)($none)(ansi rst)"
                    }
                } else {
                    for t in $r.threads {
                        print-thread $t $flt $root $cwd
                    }
                }
                print ""
            }
        }
    }
}
