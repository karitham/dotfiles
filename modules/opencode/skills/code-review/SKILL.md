---
name: code-review
description: >
  Reference for high-signal code reviews. Use when reviewing a diff, commit,
  branch, pull request, or completed implementation to qualify changed files,
  find demonstrable bugs and material missed opportunities, suppress style and
  low-value comments, and rank findings by Tier 0-2. Trigger keywords: code
  review, review changes, review diff, review PR.
license: MIT
metadata:
  author: kar
---

# Code review

These guidelines define what to inspect, what to report, and how to prioritize findings. The caller defines the intended behavior and exact review target.

A review finds problems that justify interrupting the author. It does not list every possible improvement.

## Review surface

Start from the changed files. Read each changed file in full, then read the callers, callees, tests, schemas, and configuration needed to establish the changed behavior.

Qualify each file before reviewing it:

- Critical files change business behavior, data writes, authorization, trust boundaries, public contracts, schemas, migrations, concurrency, resource ownership, or deployment behavior. Review these deeply.
- Supporting files test, adapt, configure, or document changed behavior. Check whether they preserve the intended contract and cover the risky paths.
- Mechanical files contain generated output, vendored code, lock data, formatting-only changes, or pure renames. Verify their origin and consistency. Do not line-review generated or vendored content.

Report the critical files and the reason each one matters. Group supporting and mechanical files unless one needs an individual explanation.

BAD:

    Important files: src/**/*.go

GOOD:

    Critical:
    - internal/billing/charge.go: changes idempotency and the payment write path.
    - migrations/042_add_charge_key.sql: changes the uniqueness contract used by that path.
    Supporting: charge tests and API adapter.
    Mechanical: go.sum.

## Evidence threshold

Report a finding only when the changed code causes a demonstrable failure or misses a material improvement that belongs in the current change. Establish the triggering input, state, environment, or execution path. State the resulting behavior and point to the changed line that introduced it.

Inspect the repository before inferring intent. Check project instructions and existing tests. Compare nearby implementations when they can confirm a contract. Run focused read-only checks when they distinguish a real problem from a plausible concern.

Keep findings scoped to the change. A pre-existing defect is reportable only when the change makes it reachable, makes its outcome worse, or claims to fix it but does not. Combine multiple symptoms from one cause into one finding.

BAD:

    [Tier 1] This map access may fail if the key is missing.

GOOD:

    [Tier 1] Preserve unknown webhook types instead of acknowledging them - internal/webhook/handler.go:87

    Stripe sends newly introduced event types before this service has handlers for them. The new default branch returns 200 after dropping those events, so Stripe does not retry and the event is permanently lost. Return the existing unsupported-event error from this branch so the endpoint responds with the retryable status.

## Reportable problems

Report correctness failures such as wrong conditions, missing state transitions, invalid assumptions, broken error paths, contract mismatches, unsafe boundary handling, races, leaks, and backwards-incompatible schema or API changes.

Report security defects when changed code permits unauthorized access, injection, secret disclosure, unsafe deserialization, or another concrete trust-boundary failure.

Report performance defects only when the changed path is hot or processes unbounded input and the cost is materially worse at realistic scale. Name the scale or workload that triggers the problem.

Report a missing test only when one focused test would protect a material behavior that the implementation currently gets wrong or leaves unverified at a risky boundary. Name the case and the regression it catches.

BAD:

    [Tier 2] Add more unit tests for edge cases.

GOOD:

    [Tier 1] Exercise duplicate delivery before enabling webhook retries - internal/webhook/handler_test.go:142

    The retry path now calls `Insert` before checking the delivery key. A duplicate delivery therefore returns a uniqueness error instead of the stored response. Add the duplicate-delivery case to this table and move the lookup ahead of `Insert`; the test protects the endpoint's idempotency contract.

## Material opportunities

A missed opportunity is reportable when the current change already exposes the relevant boundary and a bounded change would materially reduce correctness risk, operational cost, or accidental complexity. Prefer an established repository abstraction over a second source of truth. Prefer enforcing a new invariant at the boundary over distributing checks across callers.

Do not use this category for personal design preferences. The opportunity must have a concrete benefit in the current change and a specific implementation direction.

BAD:

    [Tier 2] Consider introducing a generic repository layer for maintainability.

GOOD:

    [Tier 2] Use the existing transaction helper for the new two-write operation - internal/accounts/merge.go:61

    `MergeAccount` writes the owner and memberships separately even though `store.WithTx` already covers this store. Using that helper here prevents the new partial-merge state when the membership write fails and removes the compensating cleanup branch.

## Suppressed comments

Do not report:

- formatting, naming, import order, comment wording, or other style preferences;
- subjective refactors with no demonstrated behavioral or operational benefit;
- speculative future requirements or defensive checks for states the system excludes;
- micro-optimizations without a realistic workload;
- generic requests for tests, documentation, logging, metrics, or comments;
- low-confidence suspicions that further inspection did not confirm;
- unrelated pre-existing problems;
- findings that a required formatter or linter reports as style-only output.

Do not include suppressed comments in an appendix or low-priority section. Silence is the correct result when a comment is not worth the author's time.

BAD:

    [Tier 2] Rename `res` to `response` for clarity.

GOOD:

    No finding.

## Priority tiers

Assign priority from required action, not theoretical blast radius.

- Tier 0: Stop the change. The defect can cause data loss or corruption, an exploitable security failure, a broad outage, or an unrecoverable public contract break under expected use.
- Tier 1: Fix before merge. The change produces an incorrect result, violates a contract, fails a realistic error path, or creates a substantial reliability or performance regression.
- Tier 2: Address in this change if practical. The code works on its primary path, but a specific bounded improvement would remove material risk, operational cost, or accidental complexity introduced by the change.

Suppress anything below Tier 2. Do not inflate priority because a finding concerns security, concurrency, or persistence; use the concrete trigger and effect.

BAD:

    [Tier 0] A malformed optional color value returns 400 instead of using the default.

GOOD:

    [Tier 1] Keep the documented default for an omitted color - api/theme.go:44

    Clients created before this field was added omit it. The new validator treats omission as an empty invalid value, so those clients now receive 400. Apply the documented default before validation to preserve compatibility.

## Output

Return two sections:

1. `Review surface`: critical files with reasons, followed by grouped supporting and mechanical files.
2. `Findings`: findings ordered by Tier 0, Tier 1, then Tier 2.

Format each finding as:

    [Tier N] Imperative title - path/to/file.ext:line

    Trigger and evidence. Resulting behavior and why it matters. Smallest credible fix direction.

Use the narrowest useful line range. A reader must understand the defect without reconstructing the full review. Do not include praise, a change summary, style notes, or a list of checks that passed.

When no issue meets the threshold, write `No reportable findings.` after the review surface.

## Example

Input: Review a payment retry change that modifies `charge.go`, `charge_test.go`, a SQL migration, and `go.sum`.

Output:

    Review surface

    Critical:
    - internal/billing/charge.go: changes retry idempotency and payment writes.
    - migrations/042_add_charge_key.sql: defines the uniqueness contract for retries.
    Supporting: internal/billing/charge_test.go.
    Mechanical: go.sum.

    Findings

    [Tier 0] Make the idempotency key unique per merchant - migrations/042_add_charge_key.sql:8

    Two merchants can receive the same provider retry key. The new global unique index rejects the second merchant's valid charge, and the handler then returns the first merchant's stored result. Index `(merchant_id, retry_key)` and query by both columns so retries cannot cross tenant boundaries.

Reference: https://github.com/anomalyco/opencode/blob/dev/packages/core/src/plugin/command/review.txt
