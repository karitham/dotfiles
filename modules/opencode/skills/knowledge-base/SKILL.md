---
name: knowledge-base
description: >
  Conventions for the persistent markdown knowledge base in ~/notes/wiki.
  Use when recording session outcomes ("record what we did", "save this
  decision to my notes"), ingesting sources ("ingest this URL/paper/file
  into my notes"), answering from accumulated knowledge ("what do my notes
  say about X"), or health-checking the wiki (orphans, broken links,
  contradictions). Do NOT use for editing personal notes outside wiki/ —
  everything there is human-written and read-only evidence.
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

### 3. Record / Ingest

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

### 4. Query

Answer from wiki pages and human notes (read-only), citing a path for
every claim. Search all scopes. Answers worth keeping get filed into the
scope they belong to so explorations compound.

### 5. Lint

On request, or after bulk ingest: orphan pages, broken links, stale
index entries, recurring terms lacking a page, contradictions between
pages — requested scope unless told otherwise. Fix mechanical breakage
directly; report judgment calls.

### 6. Log

After every operation append to `log.md`:

    ## [YYYY-MM-DD] <record|ingest|query|lint> | [scope] <subject>

and update `index.md` in the same pass. Gaps and open questions go into
`log.md`, never into speculative prose.

## Constraints

- MUST NOT create, edit, or delete anything under `~/notes` except within
  `wiki/` — everything else belongs to the human.
- MUST NOT delete wiki pages — mark superseded/archived instead so
  history and inbound links survive.
- MUST NOT state facts without a citation — if the corpus cannot answer,
  say so and log the gap.
- MUST NOT create a new scope without explicit request — guessed scopes
  fragment the knowledge base.
- SHOULD prefer enriching an existing page over near-duplicates.
- SHOULD convert PDF/DOCX sources with `pandoc` before ingestion.
