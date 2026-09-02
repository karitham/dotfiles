---
name: knowledge-query
description: >
  Read-only queries against the wiki at ~/notes/wiki. Use when a question may
  be answered from accumulated notes. It never writes; dispatch the
  knowledge-worker agent to record or edit.
license: MIT
metadata:
  author: kar
---

# Knowledge base queries

The Obsidian vault at `~/notes` holds a persistent knowledge base. The curated part lives in `~/notes/wiki`; everything else in the vault is human-written evidence. Both are readable through this protocol. Neither is writable through it.

## Layout

    ~/notes/wiki/
    ├── index.md      # catalog: link + one-line summary per page
    ├── log.md        # append-only operation record, scope-tagged
    ├── common/       # context-free knowledge
    │   └── entities/ concepts/ sources/ syntheses/
    └── <scope>/      # one dir per context, same four subdirs

A scope separates one context from another. Page types: `entities/` holds people, orgs, products, projects; `concepts/` holds ideas, techniques, frameworks, one per page; `sources/` holds one page per ingested source; `syntheses/` holds durable answers, comparisons, overviews.

Every page starts with YAML frontmatter: `type`, `updated`, `sources`.

## Steps

### 1. Orient

Read `index.md` and the last ~20 lines of `log.md`. The index lists every page with a summary; the log shows recent operations.

If `wiki/` does not exist, the knowledge base is empty. Report that and stop.

### 2. Search

Grep across every scope, not only `common/`. Search the human notes outside `wiki/` as well, because pages cite them as sources. Follow wiki-links between pages; the links connect most of the corpus.

**Constraints:**

- MUST NOT restrict the search to one unnamed scope, because matching knowledge often sits in another context.

### 3. Answer

State each claim with the path that supports it. Separate what pages state from what was derived, and mark derived statements as inference.

**Constraints:**

- MUST NOT state a fact without a citation, because an uncited claim cannot be checked against its source.
- MUST NOT fill a gap with freshly derived guesses; a derivation presented as corpus knowledge misleads later sessions.

### 4. Report gaps

When the corpus cannot answer the question, state that plainly and name the missing subject. When an answer is worth keeping, propose dispatching the `knowledge-worker` agent so the result compounds instead of staying session-local.

## Constraints

- MUST NOT create, edit, or delete anything under `~/notes`. Writes belong to the knowledge-worker agent, and everything outside `wiki/` belongs to the human.
- SHOULD prefer citing an existing page over restating its content, so answers stay consistent with the corpus.
- When pages disagree, cite both claims with their paths and `updated` dates. Prefer neither; contradiction resolution belongs to the write side, and the human decides.
- A term that appears everywhere but has no page is a recurring-term gap: report it; do not create the page here.
