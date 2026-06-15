---
name: prr
description: Reference for the prr offline PR review file format. Covers comment types (PR-level, file, inline, spanned), snips, code suggestions, format constraints, common mistakes, and troubleshooting. Load when generating, validating, or editing a `.prr` file. The `review` skill loads this as needed.
---

# prr — File Format Reference

A `.prr` file is a PR diff, quoted with `> `. Non-quoted text between quoted lines becomes a comment. File layout, top to bottom:

1. Optional PR-level review comment (free text, before any `> ` content)
2. Optional `@prr` directive (`approve` | `comment` | `reject`) — **required for `prr submit`**
3. Quoted diff, with comments interleaved

## Comment types

**PR-level review comment** — free text at the very top of the file, before any `> ` content. You get exactly one. Use for overall feedback that doesn't attach to a line.

**File comment** — non-quoted text immediately after the `> diff --git ...` header, before any `> index`/`> ---`/`> +++` lines. Attaches to the whole file.

**Inline comment** — non-quoted text on the line(s) right after a `> ` diff line. Attaches to that single line.

**Spanned inline comment** — like inline, but covers multiple lines. To **open** a span, insert a blank line before a `> ` line. To **close** it, follow the span with a non-quoted comment line. The blank line opens; the comment closes.

**Snip** — `[...]` or `[..]` on its own line. Replaces contiguous `> ` lines from the diff. Use to focus the review file on what matters.

## Code suggestions

Inside any comment block, a fenced ` ```suggestion ` block renders as GitHub's "suggested change" button. Use to propose concrete edits:

```
> +old line

How about:

```suggestion
new line
```

> +next line
```

## Review directive

Place near the top of the file, before any `> ` content:

```
Overall this is solid; a few nits below.

@prr comment   # or: approve, reject
```

Without one, `prr submit` errors.

## Constraints

- MUST preserve every `> ` line from the original diff verbatim. Only `[...]` may remove quoted content.
- MUST have a blank line between a `> ` line and its inline comment.
- A blank line before a `> ` line OPENS a span. Every open span MUST be closed by a non-quoted comment.
- A blank line between a comment and a `[...]` snip is **forbidden when more `> ` content follows** — the comment becomes stranded and the snip is misinterpreted. Put the snip directly after the comment (no blank line) or close the span differently.
- Snips (`[...]` or `[..]`) MUST be on their own line, between quoted sections.
- File comments go immediately after `> diff --git`, not after the `> index`/`> ---`/`> +++` lines.
- A PR-level review comment goes before any `> ` content and is the only non-quoted text outside inline/file comments.
- The `@prr` directive is required for `prr submit`.

## Common Mistakes

### Unterminated span

A blank line before `> ` opens a span. Every span needs a non-quoted comment to close it.

BAD — `[...]` is not a comment, so the span stays open and `prr` errors:

```
> +line

> +next_line
[...]
```

GOOD — comment closes the span, then the snip is fine:

```
> +line

> +next_line

comment about both lines

[...]
```

### Stranded comment

A comment followed by a blank line followed by a snip followed by more `> ` content. The blank line before `[...]` makes prr treat the comment as still-open, and the snip can't resolve.

BAD:

```
> +code

my comment

[...]
> +more_code
```

GOOD — snip tight against the comment, no blank line between them:

```
> +code

my comment
[...]
> +more_code
```

### Missing directive

If `prr submit` errors with "no review event", the file is missing `@prr approve|comment|reject` at the top.

### Deleted diff lines

The most common corruption. Hand-editing the file easily drops a `> ` line. Re-run `prr get --force` to start clean.

## Vim

The upstream `prr` repo ships a `vim/` plugin with syntax and folding for `*.prr`. Add `vim/` to runtimepath or use a plugin manager. Skip if the user doesn't use Vim.

## Troubleshooting

**"Failed to resolve snips"** — `[...]` is adjacent to content it can't snip. Make sure `[...]` is between quoted sections, not stranded after a comment block.

**"Detected span that was not terminated"** — a blank line before `> ` created an open span. Add a closing comment after the span's last `> ` line, or remove the blank line.

**"Detected corruption in quoted part"** — a `> ` line was modified or deleted. Re-download with `prr get --force`.

**"no review event"** — the file is missing `@prr approve|comment|reject`. Add one at the top.

**API 401** — token missing/invalid. Check `[prr] token` in `~/.config/prr/config.toml`, or `GH_TOKEN`/`GITHUB_TOKEN` env vars.
