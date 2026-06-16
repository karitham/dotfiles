---
name: book-refs
description: >
  Loads up-to-date reference material from upstream git repos for nushell,
  zellij, jj, niri, ghostty, opencode, atuin, helix, starship, direnv, and
  flake-parts. Use when working on any of these tools and the answer depends on
  current syntax, APIs, defaults, or behavior that may have changed since
  training cutoff. Fetches chapters on demand via raw.githubusercontent.com;
  always cites the raw source URL.
---

# Book Refs

Source-of-truth reference material for tools you use, fetched on demand from
their public git repos. Training data is outdated; this skill exists so the
agent pulls fresh chapters instead of guessing.

## When to use

Working on any tool in the table below — the per-reference files hold the
curated chapter index and URL pattern. Especially valuable for tools that
release frequently or where hallucinated syntax costs real debugging time.

## When NOT to use

- General shell scripting (bash, fish, zsh) — different tools
- Languages like Go, Rust, Python — no markdown source of truth available
- Trivial lookups where the training-data answer is obviously stable

## Procedure

1. Identify which tool is in scope from the user's request.
2. Read `references/<tool>.md` for that tool's source URL pattern and curated
   chapter index.
3. Pick the most relevant chapter(s) for the task. MUST NOT load the whole
   book — chapters are large and most are not relevant.
4. Fetch only those chapters from the URL pattern in the reference file.
5. Cite the raw URL when quoting or paraphrasing — the user must be able to
   verify the source.
6. If a chapter is renamed or moved, fall back to the contents API listed in
   the reference file to find the current location.

## Tools

| Tool | Trigger keywords | Reference |
|---|---|---|
| nushell | `nu`, `.nu`, nushell, pipeline, dataframe, polars | `references/nushell.md` |
| zellij | zellij, layout, keybinding, terminal multiplexer, pane | `references/zellij.md` |
| jj | `jj`, jujutsu, revset, bookmark, colocate | `references/jj.md` |
| niri | niri, scrollable-tiling, wayland compositor, output, workspace | `references/niri.md` |
| ghostty | ghostty, terminal, GPU terminal, shell-integration, terminfo | `references/ghostty.md` |
| opencode | opencode, coding agent, MCP, LSP, provider, skill, agent | `references/opencode.md` |
| atuin | atuin, shell history, history sync, ctrl-r | `references/atuin.md` |
| helix | helix, `hx`, modal editor, treesitter, selection, picker | `references/helix.md` |
| starship | starship, prompt, cross-shell, module | `references/starship.md` |
| direnv | direnv, `.envrc`, shell hook, allow | `references/direnv.md` |
| flake-parts | flake-parts, flake modules, perSystem, mkOption | `references/flake-parts.md` |

## Caching

- Fetch each chapter at most once per session. After fetched, reference from
  context — MUST NOT re-fetch the same file in the same session.
- Across sessions the agent refetches. This is the cost of always-fresh data;
  the alternative is stale training data.
