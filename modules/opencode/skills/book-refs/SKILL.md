---
name: book-refs
description: >
  Fetch current reference chapters for pinned tools from their upstream repos
  instead of trusting training data. Use when working on nushell, zellij, jj,
  niri, ghostty, opencode, atuin, helix, starship, direnv, flake-parts, or
  nixpkgs lib. Do not use for stable lookups or general shell scripting.
---

# Book Refs

Source-of-truth reference material fetched on demand from the tools' public git repos. Training data is outdated; pull fresh chapters instead of guessing.

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

For writing or refactoring Nix, use the `nixpkgs-lib` reference: `lib.*`
semantics shift between nixpkgs revs, so fetch the doc comment at the pinned
rev instead of trusting training data.

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
| nixpkgs-lib | nixpkgs, `lib.*`, nixos module, nix module, flake, overlay, package set, callPackage, mkIf, mkMerge, genAttrs | `references/nixpkgs-lib.md` |

## Caching

- Fetch each chapter at most once per session. After fetched, reference from
  context — MUST NOT re-fetch the same file in the same session.
- Across sessions the agent refetches. This is the cost of always-fresh data;
  the alternative is stale training data.
