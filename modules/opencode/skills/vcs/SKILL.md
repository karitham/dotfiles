---
name: vcs
description: This repository's jj workflow: commit style, six local workflows, and hard rules. Use for any VCS operation here. Never run git.
---

# VCS Skill: Jujutsu (jj)

You use jj, not git. Command syntax comes from `jj help <command>`; query syntax from `jj help revsets` and `jj help filesets`. This skill covers what help does not: the mental model, the workflows, and the rules.

## Mental Model

- **Working copy IS a commit** (`@`) — no staging area, no `git add`. Edits auto-snapshot on every command.
- **Change IDs are stable** — survive rebase, split, absorb. Refer to the same logical change forever. Git commit hashes change on rewrite, change IDs don't.
- **Operation log** — every command is an operation. `jj op log` to see history. Undo is trivial and safe.
- **Immutable commits** — jj won't rewrite commits on tracked bookmarks by default. Use `--ignore-immutable` to force.
- **Bookmarks, not branches** — jj calls them bookmarks. They work like git branches functionally.

## Workflows

These are local-only workflows. Fetch is fine, push is not.

### 1. Stack & Commit

Build a linear chain of commits. Each `jj commit` finalizes `@` and creates a fresh empty `@` on top. No bookmarks needed.

```
jj new main -m "task"
# ...code...
jj commit -m "feat: add widget"
# ...code...
jj commit -m "feat: wire up widget API"
```

Before writing new commits, inspect 2-3 existing commits in the repo and match their style exactly: subject line length, prefix conventions (`feat:`, `fix:`, `drop`, etc.), body vs single-line, capitalisation. Never invent a new style.

**Commit message subject line MUST be 50 characters or fewer.** Body lines SHOULD wrap at 72 characters. If wrapping at 72 would introduce ambiguity, match the existing repo convention instead.

### 2. Fixup on Top

Forgot something after committing? Stack a fix on top instead of amending — no history rewrite.

```
jj commit -m "fixup: export widget from module"
```

The fixup is its own commit, so reviewing stays clear about what was original and what was the fix.

### 3. Absorb Fixups

When a fixup belongs in an earlier commit (e.g. a test that belongs in the test commit), let jj find the target:

```
jj commit -m "fixup"
jj absorb
```

`jj absorb` compares working-copy changes against all previous commits and moves each hunk into the commit that last touched those lines. Hunks without a clear target stay in `@`.

### 4. Rebase Stack onto Main

Sync the stack with upstream. Rebase the whole branch in one step — never individual commits one by one.

```
jj git fetch
jj rebase -b @ -o main             # entire branch onto main
jj rebase -b my-feature -o main    # or a specific bookmark
```

### 5. Conflict Resolution

jj always succeeds — conflicts are stored in the commit, not errors. Never undo to escape a conflict; resolve in place.

```
jj log -r 'conflict()'             # find conflicted commits
jj new ABC1234                     # sit on the first conflicted commit
# ...edit conflicted files...
jj squash                          # move the resolution in; descendants auto-rebase
```

Pattern: `jj new CONFLICTED_COMMIT` → resolve files → `jj squash`. Repeat per conflicted commit. `jj resolve` (interactive) is the alternative.

### 6. Insert a Commit Mid-Stack

```
jj new -B DEF5678 -m "feat: missed step"
```

`-B` (insert-before) creates a commit between DEF5678's parent and DEF5678; existing children auto-rebase on top.

## Command Index

One line per command; `jj help <command>` for flags and details.

- `jj log --limit 5` — history; add `-p` for patches, `--no-graph` for a flat list
- `jj diff -r @-` — what the parent changed; `-s` summary, `--git` git format
- `jj file show -r REV PATH` — file content at a revision
- `jj st` — working copy status
- `jj describe -m "msg" -r ABC1234` — set a revision's description
- `jj split [PATH] [-r REV]` — split a commit interactively or move paths out
- `jj restore [PATH] [--from REV]` — discard changes; `--changes-in ABC1234` reverts a whole revision
- `jj resolve [PATH]` — interactive conflict resolution
- `jj prev` / `jj next` / `jj edit REV` — move the working copy commit
- `jj bookmark list --all-remotes` — bookmarks; `jj bookmark create|set|move|delete|track` to manage
- `jj op log -p` — operation history with changes
- `jj undo [--operation ID]` — undo an operation, itself reversible
- `jj git fetch` — the only allowed remote operation

## Rules

- **MUST** use `jj commit -m "message"` to commit (NOT `jj describe`, NOT `jj new` alone) — `commit` is the atomic "set message + start fresh" checkpoint.
- **MUST** use **change IDs** (first 7 chars from `jj log`) to refer to revisions, not git commit hashes.
- **MUST** run `jj st` before any commit operation.
- **MUST** use `jj log --limit N` to limit output (NOT `@-5..@` — that revset syntax is invalid).
- **MUST** use `jj file show -r REV PATH` to view file contents at a revision. The `REV:PATH` fileset syntax is NOT accepted.
- **MUST NOT** run `jj git push` under any circumstances — that's the user's responsibility.
- **MUST NOT** use git commands directly — this repo uses jj as the primary VCS.
- **SHOULD** use `jj absorb` instead of `jj squash` when fixups belong in earlier commits — it's automatic and less error-prone.
- **SHOULD** use `jj undo` on mistakes — it's safe, reversible, and works on almost any operation.
- **SHOULD** run `jj git fetch` before `jj rebase -b @ -o main` to stay synced.
