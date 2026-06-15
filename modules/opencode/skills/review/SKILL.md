---
name: review
description: Workflow for reviewing a GitHub PR offline using prr. Covers reading PR context, fetching the diff into a .prr file, supporting the user as they write inline comments in their editor, and validating the file. Use when the user wants to review a pull request, prepare a review, or run prr get/edit/status. Do NOT run prr submit — the user posts reviews themselves. Do NOT use for non-PR work (general codebase exploration, RFCs, etc.).
---

# Reviewing a Pull Request

The user does the reading and writing in their editor. Your job is to fetch, validate, and hand off. The user runs `prr submit` themselves — you never post a review to GitHub.

## Workflow

1. **Read context** — pull the PR description, linked issues, and any prior review comments. Don't dive into the diff blind.
2. **Fetch the diff** — `prr get owner/repo/N` writes the review file to `workdir/owner/repo/N.prr` and prints the path. Confirm if the file exists; pass `--force` to overwrite.
3. **Open the file** — read it with the read tool, or have the user open it via `prr edit`.
4. **User writes feedback** — they type comments inline between the `> ` diff lines. Don't pre-fill unless asked.
5. **Validate** — read the file back. Check it against the `prr` skill's constraints. Fix obvious mistakes silently; flag anything ambiguous (e.g. an unterminated span the user might have meant to extend).
6. **Pick a directive** — `@prr approve` | `comment` | `reject`. Ask the user if it's not obvious from the comments.
7. **Hand off** — the user runs `prr submit owner/repo/N` themselves. Do not run submit. Once the file is validated and a directive is in place, print the submit command and stop.

## What the user is doing

The typical flow is: open the `.prr` file in their editor, write comments inline, edit some `> ` lines by mistake, ask the model to clean it up, add a directive, then run `prr submit` themselves. Be tolerant of formatting slips — fix the file rather than reject it.

## If prr isn't installed

Say so and point at https://doc.dxuuu.xyz/prr/ for installation. Don't try to substitute a different tool mid-flow.

## See also

- `prr` skill — file format reference (comment types, snips, constraints, common mistakes, troubleshooting)
