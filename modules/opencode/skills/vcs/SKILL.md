---
name: vcs
description: Jujutsu version control workflow. Provides jj commands for log, diff, file view, status, commit, and undo. Use when viewing history, inspecting files, checking status, committing changes, or any version control operation.
---

# VCS Skill

You are using Jujutsu (jj), not git. jj is the primary VCS.

## Key Differences from Git

- **Working copy IS a commit** — no staging area, no `git add`
- **Change IDs are stable** — unlike commit hashes, they survive rewrite
- **Auto-snapshot** — changes auto-save on every command

## Discovery Commands

### View history

```
jj log
jj log -r @-5..@            # last 5 commits
jj log -r master::          # all commits from master
```

### View file at revision

```
jj file show <revision>:<path>
jj file show @:src/main.rs   # current working copy
```

### See diff

```
jj diff
jj diff --git              # git-compatible format
jj diff -r @-             # diff vs parent
```

### Check status

```
jj st
```

## How to Commit

Use `jj commit -m "message"` to commit changes.

This is equivalent to `jj describe -m "message"` followed by `jj new`.

**TL;DR**: Use `jj commit -m "message"` to commit. NOT describe, NOT new, NOT squash.

## Rules

- MUST use `jj commit` command to finalize changes (NOT describe, NOT new alone)
- MUST use change IDs (first 7 chars) not commit hashes
- MUST run `jj st` before any commit operation
- SHOULD use `jj undo` if you make a mistake
- NEVER push — that's the user's responsibility