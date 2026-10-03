---
name: knowledge-base
description: >
  Conventions for the wiki at ~/notes/wiki: sync with origin, record
  outcomes, ingest sources, lint, and publish. Use when the user wants
  something saved to or changed in their notes; use knowledge-query for
  read-only questions.
license: MIT
metadata:
  author: kar
---

# Knowledge base

Persistent, compounding wiki inside the Obsidian vault at `~/notes`.
Compile once, keep current, never re-derive from scratch. Everything
outside `wiki/` is human-written — evidence to read, never to edit.

## Layout

Scopes keep contexts separate. `common/` is the default; a new scope is
created only on explicit human request.

    ~/notes/wiki/
    ├── index.md      # catalog of every page: link + one-line summary
    ├── log.md        # append-only record of every operation, scope-tagged
    ├── common/       # context-free knowledge
    │   └── entities/ concepts/ sources/ syntheses/
    └── <scope>/      # one dir per context, same four subdirs

Page types: `entities/` people, orgs, products, projects; `concepts/`
ideas, techniques, frameworks — atomic, one per page; `sources/` one page
per ingested source (URL, author, date); `syntheses/` durable answers,
comparisons, overviews.

Every page starts with YAML frontmatter: `type`, `updated`, `sources`
(paths or URLs). Separate what sources state from what you inferred;
mark inference as inference.

Citation forms: web material → its URL; non-repo local files → absolute
path; anything git-tracked outside `~/notes` → remote URL plus the commit
SHA that was read (`<repo-url>`, commit `<sha>`, path) alongside the
local path — the pin keeps the claim reproducible as the repo drifts,
the path stays grep-able on machines that have the clone.

## Steps

### 1. Orient

Read `index.md` and the last ~20 lines of `log.md` before anything else.
If `wiki/` does not exist yet, scaffold the layout above.

### 2. Resolve scope

- Explicitly named in the request → use it.
- Unnamed → look for evidence: existing pages, the vault's AGENTS.md
  scope hints, which topic dirs cover the domain. A match proposes it.
- Still unclear → write nothing; ask which scope to use.

### 3. Sync

Run this before the first write of a run. The vault is a colocated
jj + git repo; reconcile with origin so the later commit fast-forwards
cleanly.

1. `jj st` to see the working copy, then `jj git fetch`.

   Do not rebase with `-b @`. When local wiki commits are ahead of
   origin, jj anchors that revset at the empty working-copy commit and
   re-parents origin's commit above the local one, silently taking
   origin's content. Use the local chain root instead.

2. Rebase the local chain onto upstream. The chain root is the oldest
   commit that is not already on `main@origin`:

       jj bookmark set main -r @-    # only if `main` is conflicted after fetch
       jj log -r 'roots(::@ & ~::main@origin)' --no-graph -T change_id
       jj rebase -s <that change id> -o main@origin

   `jj git fetch` leaves `main` conflicted (`main??`) when local and
   origin diverged; point it at the local commit then. If `main` is not
   conflicted it is already correct and `jj bookmark set` can fail with
   "Refusing to move bookmark backwards or sideways" — skip it.
   When the vault has no unpushed commits, `roots(...)` is the empty
   working-copy commit `@`, so the rebase is a no-op.
3. Resolve conflicts. `jj log -r 'conflicts()'` lists them.
   - Working copy: edit the file to the intended content and delete every
     conflict marker (their form follows `ui.conflict-marker-style`); jj
     snapshots the fix.
   - Committed revision C: the conflict is materialized in the working
     copy too. Edit the file there to the intended content, then squash
     only that path into C: `jj squash --into C <path>`. Restrict it to
     the conflicted path (`wiki/index.md`, `wiki/<scope>/...`) so
     untracked or out-of-scope files in the working copy are not swept
     into C. Repeat until `jj log -r 'conflicts()'` is empty.
   - Never `jj new C` or `jj edit C`: moving the working copy onto the
     conflicted revision deletes uncommitted files outside `wiki/`.
   - A conflict outside `wiki/` is never guessed at: stop and report.
4. Verify the rebase kept the local work: `jj log -r 'conflicts()'` must be
   empty and `jj diff -r 'main@origin..@'` must show the local wiki
   changes. If a local edit is missing, stop and report before writing
   anything.
5. Commit pre-existing work in this operation's paths so it does not mix
   with the new work:

       jj commit -m "wiki: <what the diff does>" \
         wiki/<scope> wiki/index.md wiki/log.md

   Prefix the subject with the scope when it is not `common`:
   `wiki/<scope>: <subject>`, matching recent commits (`wiki/upf: ...`).
   Run it only when `jj diff wiki/<scope> wiki/index.md wiki/log.md` is
   non-empty; a `jj commit` whose paths match nothing still creates an
   empty commit. Read the diff and name what changed, never `wip`.
   Changes outside those paths stay in the working copy; never move or
   discard them.

### 4. Record / Ingest

For each unit of knowledge (session outcome, source, decision):

- File a `sources/` page when material comes from outside the corpus;
  session-derived knowledge cites the session instead.
- Record observation context on source pages: hostname, relevant feature
  tags or config scope, date. Facts observed on one machine may not
  generalize to others.
- Before logging an observation as an open question, check whether the
  corpus already explains it — own pages, config semantics, tag
  conditionals. Write the explanation, not a mystery.
- Extract entities and concepts into their own pages. Before creating a
  page, search ALL scopes for an existing one — enrich rather than
  duplicate, cross-link scopes instead of copying.
- Update backlinks in both directions; revise any summary the new
  evidence changes. One source typically touches several pages.
- Contradictions: replace the old claim together with a dated note of
  what changed and why — never silently overwritten, never left standing
  unflagged next to its successor.

### 5. Query

Answer from wiki pages and human notes (read-only), citing a path for
every claim. Search all scopes. Answers worth keeping get filed into the
scope they belong to so explorations compound.

### 6. Lint

On request, or after bulk ingest: orphan pages, broken links, stale
index entries, recurring terms lacking a page, contradictions between
pages — requested scope unless told otherwise. Fix mechanical breakage
directly; report judgment calls.

### 7. Log

After every operation append to `log.md`:

    ## [YYYY-MM-DD] <record|ingest|query|lint> | [scope] <subject>

and update `index.md` in the same pass. Gaps and open questions go into
`log.md`, never into speculative prose.

### 8. Publish

Run this after a run that wrote to `wiki/`, or that committed pre-existing
work in §3. A question answered without filing anything writes nothing
and publishes nothing.

1. `jj st`. If `jj diff wiki/<scope> wiki/index.md wiki/log.md` is
   non-empty, commit the operation's paths the same way as §3 step 5
   (`wiki: <subject>`, or `wiki/<scope>: <subject>` for a named scope):

       jj commit -m "wiki: <subject>" \
         wiki/<scope> wiki/index.md wiki/log.md

2. Point `main` at the newest commit and push:

       jj bookmark set main -r @-
       jj git push -b main

   `@-` is the commit just made; `@` keeps any human or other-scope
   changes uncommitted, and those stay local, so the push carries only
   the wiki commits.
3. If the push is rejected because origin moved, run Sync §3 again:
   `jj git fetch`, rebase the local chain root onto `main@origin`,
   resolve conflicts, verify, then push again.
4. Report the commits pushed.

## Constraints

- MUST NOT create, edit, or delete anything under `~/notes` except within
  `wiki/` — everything else belongs to the human. The jj sync/publish
  commands are the sanctioned exception: they touch VCS metadata and
  remote state, never file content outside `wiki/`.
- MUST NOT commit or push paths outside `wiki/<scope>`, `wiki/index.md`,
  and `wiki/log.md` — other scopes and human notes stay uncommitted in
  the working copy.
- MUST stop and report a rebase conflict outside `wiki/` — never guess at
  human prose.
- MUST leave pre-existing out-of-scope changes untouched; never reset,
  move, or discard them. In particular, never run `jj new` or `jj edit`
  onto a revision while the working copy holds uncommitted human or
  other-scope files — it deletes them. Squash conflict resolutions into
  a committed revision with `jj squash --into C <path>`, path-limited to
  the conflicted `wiki/` file.
- MUST run Sync and Publish only around a run that writes to `wiki/`; a
  question answered without filing anything must not touch VCS state.
- MUST NOT delete wiki pages — mark superseded/archived instead so
  history and inbound links survive.
- MUST NOT state facts without a citation — if the corpus cannot answer,
  say so and log the gap.
- MUST NOT create a new scope without explicit request — guessed scopes
  fragment the knowledge base.
- SHOULD prefer enriching an existing page over near-duplicates.
- SHOULD convert PDF/DOCX sources with `pandoc` before ingestion.
