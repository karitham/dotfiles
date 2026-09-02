---
name: jj
description: >
  The jj mental model: working copy as commit, change IDs, anonymous branches,
  revsets, merges, and conflicts as data. Use when jj behavior is confusing or
  when translating git habits. For this repository's commit rules, load vcs.
---

# jj concepts

Commands operate on repository data, not on the working copy. The working copy is itself a commit, so most commands edit the database and leave `@` in place. Rebases always succeed because a conflict is recorded as data in the commit, never raised as an error.

- The working copy is a commit. Nothing is uncommitted, and editing files amends `@`.
- Change IDs name the logical change across rewrites; commit IDs name content. Refer to changes by change-ID prefix.
- Describe intent first. Create the change, describe what it will do, refine the description as you work. Git commits after the fact; jj describes before.
- Two changes sharing a parent are a branch. Branches are anonymous by default; name one only when the name adds value. `jj log -r 'heads(all())'` lists every head.
- A merge is a change with multiple parents, so `jj new A B C` merges any number of changes. There is no `jj merge`.
- Conflicted commits store conflict markers (`+++++++` starts the snapshot, `%%%%%%%` starts the diff) and descendants keep working. Resolving the conflict rebases descendants automatically; the fix propagates.

## Revsets

`-r` on almost every command takes a revset and defaults to `@`. Symbols name single commits: `@`, change IDs, commit IDs. Operators: `@-` parent, `@+` child, `::x` ancestors, `x::` descendants, `&` intersection, `|` union. Functions: `heads(x)`, `description(substring:x)`, `mine()`, `trunk()` (the remote main, master, or trunk bookmark). A useful log for larger repositories: `jj log -r '@ | ancestors(remote_bookmarks().., 2) | trunk()'`.

## Moves

- Squash workflow, the git-index equivalent: describe the change, run `jj new` for an empty scratch change on top, work in the scratch, then `jj squash` moves it into the described change. `jj squash PATH` stages one path; `jj squash -i` selects hunks interactively. `jj abandon` discards the scratch change. `jj squash` is short for `--from @ --into @-` and works between any change and its parent.
- Edit workflow: `jj new -B @ -m "desc"` inserts a change before `@` and rebases descendants; make the fix there, then `jj next --edit` returns to the following change.
- Rebase scope: `-r REV` moves one revision, `-b REV` its whole branch, `-s REV` the revision plus descendants; `-o DEST` sets the destination.

Source: https://steveklabnik.github.io/jujutsu-tutorial/
