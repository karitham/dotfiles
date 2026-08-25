# Knowledge-base benchmark & test plan

Durable evaluation harness for the knowledge-base skill and its executors
(knowledge-worker subagent, primary agents running the skill inline, future
models). Goal: prove that knowledge workers correctly **find, structure,
and enhance** accumulated research over time.

## Principles

- **Executor-agnostic**: every task is phrased so any agent can run it.
  During iteration, executors ALWAYS read the live skill from its repo
  path (`modules/opencode/skills/knowledge-base/SKILL.md`) — deployed
  copies under `~/.config/opencode/skills/` are frozen home-manager
  snapshots that only refresh on rebuild, so registered-skill loading
  tests outdated instructions. Path-reads see every edit instantly.
- **Disk-state-only memory**: each run starts from a fresh dispatch. What
  the worker "knows" is exactly what previous runs left in `~/notes/wiki/`.
  This makes the vault itself the test fixture.
- **Deterministic where possible**: structural rules are enforced by
  `scripts/lint.sh`, not judgment. Judgment lives in the rubric and audits.

## Golden tasks

| ID | Task | Setup | Must demonstrate |
|----|------|-------|------------------|
| T1 | Cold-start compile | Empty/nonexistent `wiki/`; research a domain from local sources | Scaffolding, scope resolution, typed pages, provenance, index+log |
| T2 | Enrichment | Existing pages on the topic; supply one new source | Finds and enriches existing pages instead of duplicating; touches several pages per source |
| T3 | Grounded query | Populated wiki | Answers cite paths; unknowns logged as gaps, not invented |
| T4 | Conflict injection | Supply a source contradicting an established page claim | Supersedes with dated note of what changed and why; never silent overwrite or dual standing claims |
| T5 | Scope ambiguity | Request with no scope named and no corpus signal | Writes nothing; reports back asking which scope |
| T6 | Idempotence | Re-run a previously completed ingest | No near-duplicate pages; page count stable; log records the pass |
| T7 | Red-team audit | Second agent adversarially verifies sampled claims against sources | Misgrounded claims surface; fixes flow back through an enrich pass |

## Scoring rubric (per run)

Deterministic (`scripts/lint.sh`, must pass with zero hard failures):

- frontmatter on every page; log entry format; all wikilinks resolve;
  index lists every page; orphan warnings reported

Judgment:

- **Grounding**: sample 5 claims from the newest synthesis; verify each
  citation exists and supports the claim (T7 automates the sampling)
- **Fence**: nothing written outside `wiki/` (check via VCS status)
- **Reuse delta**: ratio of enriched-existing vs created pages on T2/T6
- **Ask-back discipline** on T5: zero writes, question returned

Record one row per run in the run ledger (below).

## Run procedure

1. Prepare fixture state (empty wiki for T1; populated for others).
2. Dispatch fresh executor with the task text and the skill path:
   `/home/kar/dotfiles/modules/opencode/skills/knowledge-base/SKILL.md`
3. Worker self-lints with `scripts/lint.sh` before reporting.
4. External grade: re-run linter, fence audit, judgment items above.
5. Append ledger row. If failures: refine SKILL.md only (never the
   dispatch prompt) and re-run — the prompt staying constant is what
   makes iterations comparable.

## Run ledger

| Date | Task | Executor | Lint | Grounding | Notes |
|------|------|----------|------|-----------|-------|
| 2026-08-25 | T1 cold-start dotfiles | knowledge-worker | PASS | 10/12 correct, 0 wrong, 2 partial | agents mischaracterized (build/plan are disabled overrides); Linear/Sentry logged as gap despite corpus explaining it; no host context recorded → skill §3 refined with context + explain-don't-mystery rules |
| 2026-08-25 | T7 red-team audit | general | n/a | found both partials above, settled HM-upstream question with store evidence | audit prompt in session log; verdicts fed to T2 |
| 2026-08-25 | T2 enrichment corrections | knowledge-worker | PASS* | all 3 findings addressed, no duplicate pages | *worker discovered lint.sh wikilink check vacuous (missing -r) → script fixed; fence held under temptation to self-patch |
