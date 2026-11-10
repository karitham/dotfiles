---
name: guided-review
description: Turn a pull request, a stack of pull requests, a branch or a local diff into a guided review page you read top to bottom - an overview with a before/after sketch of the code path, then the change step by step with the real diff behind each step, then a short list of things worth a closer look. Use when ana asks for a guided review, a walkthrough of a PR or PR stack, "help me digest this change", or a review she can scroll through rather than a dense report.
---

# guided review

A guided review is for a person who wants to understand a change before judging it. They scroll down once and come away with the big picture: what problem it solves, what it adds, in what order to read it, and what to look at twice. It is not a findings report. Findings come last and stay short.

The shape is borrowed from two tools that do this well:

- capy's guided review (capy.ai changelog 0.4.4 and 0.4.6): every PR opens on an **overview** - one sentence of context, the numbered **steps** the PR takes, and a **before / after** view. The before/after is not the diff: it is a sketch of the code path (a few lines of call skeleton, top to bottom), with removed lines red, added lines green, a faint one-line note after each changed line, and the number of the step it belongs to. Big PRs name lockfiles, generated files and wholly deleted files instead of reading them.
- guidedreview.dev ("how a review plan works"): the walk is a list of **units**, each a logical group of real hunks across files, ordered contract/schema first, then logic, then call sites; tests are their own unit right after the feature they test. The model writes order, titles and commentary only - **the code shown is always verbatim from the diff**, and a unit that points at code that isn't there is dropped.

## what the page holds

For one PR, one chapter. For a stack, a short **big picture** first (2-3 sentences plus one diagram of how the pieces connect, and a row of chapter links), then one chapter per PR in stack order.

Each chapter:

1. **title** and a faint meta line (branch -> target, files, +/-).
2. **overview**, two columns on a wide screen:
   - left: `context`, 1-2 sentences in the reader's terms (the problem or capability, not the files), then 3-6 numbered **short steps** (one line each, linking down to the full step).
   - right: 1-2 **before / after diagrams**, each at most ~12 lines: a call skeleton of the path the PR changes, `kind` same/add/del, `indent`, a short `note` on changed lines, and the `step` number it belongs to. Show the flow, not every line. A brand-new subsystem gets an "after" sketch whose lines are all add, still annotated.
3. **step by step**: for each step, a title (a full sentence), the files as chips, 2-4 sentences of explanation (why, then what), and a collapsed "show the code" with 1-3 **verbatim** diff excerpts (<= 30 lines each, from the PR's own diff, `+`/`-`/space prefixes kept).
4. **worth a closer look**: at most ~5 notes. Majors (and blockers) shown, the rest folded under "n smaller notes". Each note: severity, a title, the file:line, one or two sentences of why. Each has an "ask for this" toggle; picks go to the chat with one button.
5. a one-line **verdict**, and the files **not walked through** (generated, testdata, lockfiles, deleted whole) by name.

Close a stack with a short "where this leaves us" (the 3-5 things that matter across all PRs).

## writing rules

- Calm and sparse: the reader should digest it by scrolling, so prefer fewer, bigger ideas. No walls of text, no tables of every concern, no severity counters everywhere.
- Plain words, lowercase when the reader is ana (her preference, including headings). Explain why before what.
- Steps follow reading order, not file order: contract and data first, then the logic, then the call sites, then tests (as their own step right after what they test).
- Every changed file appears in some step or in `skipped`. Code excerpts are copied from the diff, never written.
- Notes are evidence-based and few. A note that would need a paragraph to justify belongs in a separate review, not here.

## how to make one

1. **Get the diffs.** Tangled: `tg pr view <n> --json`, `tg pr diff <n>` (await the job before saving it). GitHub: `gh pr diff`. Local: `git diff base...head`. For a stack, note each PR's target branch; build one worktree per stack level with the patches applied in order (`git worktree add --detach /tmp/gr-<n> <prev>`, `git apply --index --3way`, commit), so each PR can be read in context. Never build in ana's root checkout.
2. **Write one guide chapter per PR**, yourself for one small PR, or with one subagent per PR for a stack (read-only; give each this skill's chapter schema below, its diff path, its worktree and its stack neighbours). If you already have review notes (e.g. from an earlier review), give them as input for `notes`, but the guide is written fresh in this shape.
3. **Assemble** the guide JSON (schema below), then render and check it:
   `python3 ~/.agents/skills/guided-review/render.py guide.json out.html --diff <chapter id>=<path.diff> ...`
   It prints `check:` lines for excerpts not found in the diff, files no step names, too many steps, diagrams too long. Fix those (ask the chapter's writer) before publishing.
4. **Publish** with `artifacts.create(title, html)` (or `artifacts.update` to revise an existing guide), then **look at it** with the browser at desktop and phone width, light and dark, and check `artifacts.errors`. Read it as the reviewer would: can you get the big picture from the overview alone?

## guide JSON

```json
{
  "title": "aly's acp stack, guided",
  "lede": "one or two sentences: what this is and how to read it",
  "picture": {"text": "2-3 sentences of big picture (stack only)", "diagrams": [DIAGRAM]},
  "chapters": [{
    "id": "pr145", "ref": "#145", "title": "...", "short": "3-5 word label for the chapter links",
    "meta": "acp-output-evidence -> main - 22 files, +429 -147",
    "context": "1-2 sentences",
    "steps": [{"short": "one line", "title": "a full sentence", "files": ["path", ...],
               "explain": "2-4 sentences (blank line between paragraphs)",
               "code": [{"file": "path", "lang": "gleam|go|python|erlang|diff|...", "excerpt": "verbatim diff lines"}]}],
    "diagrams": [DIAGRAM],
    "notes": [{"severity": "blocker|major|minor|nit", "title": "...", "where": "file:line", "why": "1-2 sentences"}],
    "verdict": "merge after fixes: one sentence",
    "skipped": [{"path": "file or dir/*", "why": "generated|testdata|lockfile|deleted"}]
  }],
  "closing": {"title": "where this leaves us", "text": "paragraphs"}
}
```

`DIAGRAM` is `{"caption": "how a prompt reaches the session", "lines": [{"code": "acp.prompt(req)", "kind": "same|add|del", "indent": 0, "note": "short note on changed lines", "step": 2}]}`.
