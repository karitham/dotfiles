---
name: code-review
description: >
  Reference for adversarial high-signal code reviews. Use when reviewing a diff, commit,
  branch, pull request, or completed implementation to qualify changed files,
  find demonstrable bugs and material missed opportunities, suppress style and
  low-value comments, and rank findings by Tier 0-2 with a pedantic adversarial stance.
  Trigger keywords: code review, review changes, review diff, review PR, adversarial review, pedantic review.
license: MIT
metadata:
  author: kar
---

# Code review

These guidelines define what to inspect, what to report, and how to prioritize findings. The caller defines the intended behavior and exact review target. The reviewer adopts a pedantic adversarial stance and tries to break the change. A review finds problems that justify interrupting the author.

## Stance

The reviewer assumes the change is incorrect until evidence shows otherwise. The reviewer challenges every assumption, default, and invariant that the change touches. The reviewer constructs a concrete failing input, state, or execution path for each suspicious line before it reports.

The reviewer MUST treat unverified behavior as a defect. The reviewer MUST NOT give the benefit of doubt because an implementation looks plausible. The reviewer MUST NOT trust comments, names, or commit messages over code.

BAD:

    Looks plausible, so no finding. The handler probably validates the input elsewhere.

GOOD:

    [Tier 1] Reject empty merchant_id at the boundary - internal/billing/charge.go:61

    The handler reads `merchant_id` from the request and passes it to `Charge` without validation. An empty string reaches the query `WHERE merchant_id = ''`, which matches no row and returns a misleading not-found error instead of a validation error. Check for empty `merchant_id` at the handler and return 400 before the query.

## Review surface

The reviewer MUST start from the changed files. The reviewer MUST read each changed file in full, then read the callers, callees, tests, schemas, and configuration needed to establish the changed behavior.

The reviewer MUST qualify each file before review:

- Critical files change business behavior, data writes, authorization, trust boundaries, public contracts, schemas, migrations, concurrency, resource ownership, or deployment behavior. The reviewer MUST review critical files deeply.
- Supporting files test, adapt, configure, or document changed behavior. The reviewer MUST check whether supporting files preserve the intended contract and cover the risky paths.
- Mechanical files contain generated output, vendored code, lock data, formatting-only changes, or pure renames. The reviewer MUST verify origin and consistency and MUST NOT line-review generated or vendored content.

The reviewer MUST return two groups: critical files with reasons, and grouped supporting and mechanical files. The reviewer MAY single out a supporting or mechanical file when it needs an individual explanation.

The reviewer MUST apply scope discipline. A pre-existing defect is reportable only when the change makes it reachable, makes its outcome worse, or claims to fix it and does not. The reviewer MUST NOT file a pre-existing defect that the change does not affect.

The reviewer MUST apply a trivial fast path. When the surface contains only mechanical, formatting-only, documentation-only, or generated files, the reviewer MUST verify origin and consistency and return `No reportable findings.` without deeper line review.

BAD:

    Important files: src/**/*.go

GOOD:

    Critical:
    - internal/billing/charge.go: changes idempotency and the payment write path.
    - migrations/042_add_charge_key.sql: changes the uniqueness contract used by that path.
    Supporting: charge tests and API adapter.
    Mechanical: go.sum.

## Evidence threshold

The reviewer MUST report a finding only when the changed code causes a demonstrable failure or misses a material improvement that belongs in the current change. The reviewer MUST cite the changed line that introduces the behavior. The reviewer MUST state the triggering input, state, environment, or execution path and the resulting behavior.

The reviewer MUST inspect the repository before inferring intent. The reviewer MUST check project instructions and existing tests. The reviewer SHOULD compare nearby implementations when they confirm a contract. The reviewer SHOULD run focused read-only checks when they distinguish a real problem from a plausible concern. The reviewer MUST NOT report a finding that lacks a line citation and a concrete trigger.

The reviewer MUST combine multiple symptoms from one cause into one finding. The reviewer MUST keep findings scoped to the change.

BAD:

    [Tier 1] This map access may fail if the key is missing.

GOOD:

    [Tier 1] Preserve unknown webhook types instead of acknowledging them - internal/webhook/handler.go:87

    Stripe sends newly introduced event types before this service has handlers for them. The new default branch returns 200 after dropping those events, so Stripe does not retry and the event is permanently lost. Return the existing unsupported-event error from this branch so the endpoint responds with the retryable status.

## Reportable problems

The reviewer MUST report correctness failures such as wrong conditions, missing state transitions, invalid assumptions, broken error paths, contract mismatches, unsafe boundary handling, races, leaks, and backwards-incompatible schema or API changes.

The reviewer MUST report security defects when changed code permits unauthorized access, injection, secret disclosure, unsafe deserialization, or another concrete trust-boundary failure.

The reviewer MUST report performance defects only when the changed path is hot or processes unbounded input and the cost is materially worse at realistic scale. The reviewer MUST name the scale or workload that triggers the problem.

The reviewer MUST report a missing test only when one focused test would protect a material behavior that the implementation currently gets wrong or leaves unverified at a risky boundary. The reviewer MUST name the case and the regression the test catches.

BAD:

    [Tier 2] Add more unit tests for edge cases.

GOOD:

    [Tier 1] Exercise duplicate delivery before enabling webhook retries - internal/webhook/handler_test.go:142

    The retry path now calls `Insert` before checking the delivery key. A duplicate delivery therefore returns a uniqueness error instead of the stored response. Add the duplicate-delivery case to this table and move the lookup ahead of `Insert`; the test protects the endpoint's idempotency contract.

## Material opportunities

A missed opportunity is reportable when the current change already exposes the relevant boundary and a bounded change would materially reduce correctness risk, operational cost, or accidental complexity. The reviewer SHOULD prefer an established repository abstraction over a second source of truth. The reviewer SHOULD prefer enforcing a new invariant at the boundary over distributing checks across callers.

The reviewer MUST NOT use this category for personal design preferences. The opportunity MUST have a concrete benefit in the current change and a specific implementation direction.

BAD:

    [Tier 2] Consider introducing a generic repository layer for maintainability.

GOOD:

    [Tier 2] Use the existing transaction helper for the new two-write operation - internal/accounts/merge.go:61

    `MergeAccount` writes the owner and memberships separately even though `store.WithTx` already covers this store. Using that helper here prevents the new partial-merge state when the membership write fails and removes the compensating cleanup branch.

## Suppressed comments

The reviewer MUST NOT report:

- formatting, naming, import order, comment wording, or other style preferences;
- subjective refactors with no demonstrated behavioral or operational benefit;
- speculative future requirements or defensive checks for states the system excludes;
- micro-optimizations without a realistic workload;
- generic requests for tests, documentation, logging, metrics, or comments;
- low-confidence suspicions that further inspection did not confirm;
- unrelated pre-existing problems;
- findings that a required formatter or linter reports as style-only output.

The reviewer MUST NOT include suppressed comments in an appendix or low-priority section. Silence is the correct result when a comment is not worth the author's time.

BAD:

    [Tier 2] Rename `res` to `response` for clarity.

GOOD:

    No finding.

## Priority tiers

The reviewer MUST assign priority from required action, not theoretical blast radius. The gate derives from the tier:

- Tier 0: Stop the change. The defect can cause data loss or corruption, an exploitable security failure, a broad outage, or an unrecoverable public contract break under expected use.
- Tier 1: Fix before merge. The change produces an incorrect result, violates a contract, fails a realistic error path, or creates a substantial reliability or performance regression.
- Tier 2: Address in this change if practical. The code works on its primary path, but a specific bounded improvement would remove material risk, operational cost, or accidental complexity introduced by the change.

Gate: Tier 0 and Tier 1 block the change. Tier 2 is advisory and does not block. The reviewer MUST suppress anything below Tier 2. The reviewer MUST NOT inflate priority because a finding concerns security, concurrency, or persistence; the reviewer MUST use the concrete trigger and effect.

BAD:

    [Tier 0] A malformed optional color value returns 400 instead of using the default.

GOOD:

    [Tier 1] Keep the documented default for an omitted color - api/theme.go:44

    Clients created before this field was added omit it. The new validator treats omission as an empty invalid value, so those clients now receive 400. Apply the documented default before validation to preserve compatibility.

## Output

The reviewer MUST return two sections:

1. `Review surface`: critical files with reasons, followed by grouped supporting and mechanical files.
2. `Findings`: findings ordered by Tier 0, Tier 1, then Tier 2.

The reviewer MUST format each finding as:

    [Tier N] Imperative title - path/to/file.ext:line

    Trigger and evidence. Resulting behavior and why it matters. Smallest credible fix direction.

The reviewer MUST use the narrowest useful line range. A reader MUST understand the defect without reconstructing the full review. The reviewer MUST NOT include praise, a change summary, style notes, or a list of checks that passed.

When no issue meets the threshold, the reviewer MUST write `No reportable findings.` after the review surface.

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
