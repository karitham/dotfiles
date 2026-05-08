---
name: vcs
description: Jujutsu (jj) version control workflow for dotfiles. Covers log, diff, status, commit, absorb, rebase, split, restore, file ops, bookmarks, git fetch, undo, conflict resolution, and six common local workflows. Use for any VCS operation. Do NOT use for git commands — this repo uses jj.
---

# VCS Skill: Jujutsu (jj)

You use jj, not git. jj 0.40.0 is the primary VCS.

## Mental Model

- **Working copy IS a commit** (`@`) — no staging area, no `git add`. Edits auto-snapshot on every command.
- **Change IDs are stable** — survive rebase, split, absorb. Refer to the same logical change forever. Git commit hashes change on rewrite, change IDs don't.
- **Operation log** — every command is an operation. `jj op log` to see history. Undo is trivial and safe.
- **Immutable commits** — jj won't rewrite commits on tracked bookmarks by default. Use `--ignore-immutable` to force.
- **Bookmarks, not branches** — jj calls them bookmarks. They work like git branches functionally.

## Navigation & Discovery

### View history
```
jj log                              # default: mutable commits + context
jj log --limit 5                    # last 5 commits (preferred, simple)
jj log -r '..@' --limit 5           # same with explicit revset
jj log -r 'main::'                  # all commits from main forward
jj log -r '@- | @-- | @---'         # parent / grandparent / great-grandparent
jj log -r 'description("fix")'      # search descriptions
jj log -r 'author("kar")'           # search authors
jj log -p                           # with patch
jj log --no-graph                   # flat list (no ASCII graph)
```

### View file contents at a revision
```
jj file show -r @ path/to/file      # working copy
jj file show -r @- path/to/file     # parent revision
jj file show -r main path/to/file   # at a bookmark
```

**MUST** use `jj file show -r REV PATH` syntax. The `REV:PATH` fileset syntax is NOT accepted.

### Diff
```
jj diff                             # @ vs parent(s)
jj diff --git                       # git-format diff
jj diff -r @-                       # what @- changed (parent vs grandparent)
jj diff --from main --to @          # main vs working copy
jj diff -s                          # summary (added/deleted/modified)
jj diff --stat                      # histogram
jj diff --name-only                 # just file paths
jj interdiff --from @- --to @       # compare changes of two revisions' diffs
```

### Status & bookmarks
```
jj st                               # working copy status
jj bookmark list                    # local bookmarks (branches)
jj bookmark list --all-remotes      # all remote bookmarks
jj bookmark list --remote origin    # specific remote
```

### Operation log (command history)
```
jj op log                           # history of all jj commands run
jj op log --limit 10
jj op log -p                        # with patch of what changed
```

## Commit Workflow

### Commit (create checkpoint)
```
jj commit -m "description"
```
Sets the description on `@` and creates a new empty `@` on top. This is the primary commit command.

**MUST** use `jj commit -m "message"` to commit. NOT `jj describe`, NOT `jj new` alone. `jj commit` is the safe atomic "set message + start fresh" command.

### Amend message
```
jj describe -m "new message"        # update @ description without new commit
jj describe -m "new msg" -r ABC1234 # update any revision's description
```

## Workflows

These are local-only workflows. **Never push.** Fetch is fine, push is not.

### 1. Stack & Commit

Build a linear chain of commits. The fundamental jj workflow — you can't do this in git without naming branches.

BAD — reaching for git habits:
```
# git: stage, commit, commit...
jj new main -m "task"
# ...work...
# forgot to describe before working — now what?
jj commit -m "feat: add widget"
# ...work...
jj new           # creates dangling empty commit
jj describe -m "feat: wire up API"  # but there's already an empty commit above!
```

GOOD — just keep committing:
```
jj new main -m "task"
# ...code...
jj commit -m "feat: add widget"
# ...code...
jj commit -m "feat: wire up widget API"
# ...code...
jj commit -m "feat: add widget tests"
```
Each `jj commit` finalizes the current change and creates a fresh empty `@` on top. The chain is linear, no bookmarks needed.

**Before writing new commits, inspect 2-3 existing commits in the repo to deduce their style.** Check: subject line length, prefix conventions (`feat:`, `fix:`, `drop`, etc.), body vs single-line, capitalisation. Match it exactly. Never invent a new style.

**Commit message subject line MUST be 50 characters or fewer.** Body lines SHOULD wrap at 72 characters. If wrapping at 72 would introduce ambiguity, match the existing repo convention instead.

### 2. Fixup on Top

You made a commit but forgot something. Instead of amending into the previous commit (which rewrites history), stack a fix on top.

BAD — rewriting history unnecessarily:
```
# realized you forgot to export a function
jj describe -m "feat: add widget"   # tries to add it here
# but @ already had content, now it's mixed
```

GOOD — stack a fixup commit:
```
# ...previous commits...
jj commit -m "feat: add widget"
# oops, forgot to export the new function
jj commit -m "fixup: export widget from module"
```
The fixup is its own commit. When reviewing, it's clear what was the original vs the fix.

### 3. Absorb Fixups

When a fixup *should* live in an earlier commit (e.g. you added a test that belongs in the test commit), use `jj absorb` instead of manually squashing.

BAD — manual squash that's error-prone:
```
# fix belongs in commit ABC1234
jj squash --from @ --into ABC1234   # you have to identify the right commit
```

GOOD — let jj figure it out:
```
# make the fix in working copy
jj commit -m "fixup"
# oops, this fix actually belongs in the commit that introduced that code
jj absorb                           # auto-distributes into the right commits
```
`jj absorb` compares working copy changes against all previous commits and moves each hunk into the commit that last touched those lines. If it can't determine a target, it leaves the change in `@`.

### 4. Rebase Stack onto Main

Sync your commit stack with upstream changes. Fetch from remote, then rebase your branch.

BAD — rebasing individual commits:
```
jj git fetch
jj rebase -r ABC1234 -o main    # rebase one
jj rebase -r DEF5678 -o main    # rebase another
# each one may cause conflicts independently
```

GOOD — rebase the whole branch:
```
jj git fetch
jj rebase -b @ -o main             # rebase entire branch onto main
# OR rebase a specific bookmark
jj rebase -b my-feature -o main
```
`-b` (branch mode) rebases all commits in the working branch that aren't in main. If conflicts appear, resolve them (see Workflow 5).

### 5. Conflict Resolution

Rebasing or absorbing can create conflicts. jj always succeeds — conflicts are stored in the commit, not errors.

BAD — panic, restart:
```
# oh no, conflicts on rebase
jj undo                            # throw everything away
# start over from scratch
```

GOOD — resolve in place:
```
jj rebase -b @ -o main
# shows: "New conflicts appeared in 2 commits"
jj log -r 'conflict()'             # find conflicted commits
# resolve each conflicted commit:
jj new ABC1234                     # create on top of first conflicted commit
# ...edit conflicted files...
jj squash                          # move resolution into the conflicted commit
# repeat for each conflicted commit
```
The pattern is always: `jj new CONFLICTED_COMMIT` → resolve files → `jj squash`. Descendants auto-rebase when you squash.

### 6. Insert a Commit Mid-Stack

You need to add a commit between two existing commits in your stack.

BAD — edit and amend:
```
jj edit ABC1234                    # jump into the commit
# ...make changes...
# now @ is at ABC1234 but you wanted a new commit between ABC1234 and DEF5678
```

GOOD — insert before:
```
jj new -B DEF5678 -m "feat: missed step"
```
`-B` (insert-before) creates a new commit between DEF5678's parent and DEF5678. The existing child commits auto-rebase on top.

## Advanced Operations

### Split a commit
```
jj split                            # interactive split of @ into parent+child
jj split path/to/file               # move specific file into separate commit
jj split -r ABC1234                 # split an older commit
```

### Restore (undo changes to files)
```
jj restore                          # undo all changes in @ (keeps commit alive)
jj restore path/to/file             # undo specific file
jj restore --from main --into @     # restore file content from main
jj restore --changes-in ABC1234     # undo what a revision introduced
```

### Resolve conflicts (manual)
```
jj log -r 'conflict()'              # find conflicted commits
jj resolve                          # interactive conflict resolution
jj resolve path/to/file
```

## Remote Operations

### Fetch only
```
jj git fetch                        # fetch all remotes
jj git fetch --remote origin        # specific remote
jj git fetch -b main                # specific branch
```

**Fetch is allowed. Push is NOT.** Never run `jj git push`.

## Bookmark Management
```
jj bookmark create topic            # create at @
jj bookmark set topic -r ABC1234    # create or move bookmark to revision
jj bookmark move topic --to ABC1234 # move bookmark
jj bookmark delete topic            # delete locally
jj bookmark track origin/main       # start tracking remote bookmark
jj bookmark rename old new          # rename
```

## Navigation
```
jj prev                             # move @ to parent (new empty working copy)
jj next                             # move @ to child
jj edit ABC1234                     # set working copy to a specific revision
jj new                              # create empty commit on top of @
jj new main                         # create empty commit on top of main
```

## Undo & Recovery
```
jj undo                             # undo last operation (reversible itself)
jj undo --operation OP_ID           # undo specific operation
jj restore                          # abandon changes in @ without losing commit
jj op log                           # find the operation ID to undo
```

## Rules

- **MUST** use `jj commit -m "message"` (NOT `jj describe`, NOT `jj new` alone) — `commit` is the atomic safe checkpoint.
- **MUST** use **change IDs** (first 7 chars from `jj log`) to refer to revisions, not git commit hashes.
- **MUST** run `jj st` before any commit operation.
- **MUST** use `jj log --limit N` to limit output (NOT `@-5..@` — that revset syntax is invalid).
- **MUST** use `jj file show -r REV PATH` to view file contents at a revision.
- **MUST NOT** run `jj git push` under any circumstances — that's the user's responsibility.
- **MUST NOT** use git commands directly — this repo uses jj as the primary VCS.
- **SHOULD** use `jj absorb` instead of `jj squash` when fixups belong in earlier commits — it's automatic and less error-prone.
- **SHOULD** use `jj undo` on mistakes — it's safe, reversible, and works on almost any operation.
- **SHOULD** run `jj git fetch` before `jj rebase -b @ -o main` to stay synced.
