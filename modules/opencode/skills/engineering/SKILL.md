---
name: engineering
description: >
  Structure-first SOP for Go code. Applies Ousterhout deep modules and
  information hiding before Effective Go tactics. Loads software-architecture
  for structure and go for language checks. Use when writing, editing, or
  reviewing Go code, or when deciding whether a change needs structure or
  just tactics.
---

# Engineering

## Overview

The agent checks structure before tactics. Ousterhout defines the structure: deep modules with simple interfaces and hidden complexity. Effective Go defines the tactics: names, errors, context, and small interfaces. The agent runs the structural check first and only then polishes the function.

This SOP composes two References. `software-architecture` provides the structural principles. `go` provides Effective Go. Both remain loadable alone for focused work.

## Parameters

- **task_scope** (required): One sentence that states what the caller asked for.
- **files_changed** (optional): List of files in the change. Inferred from the diff when empty.

## Steps

### 1. Gate Scope

Decide whether structural work is in scope.

**Constraints:**

- MUST classify the task as `trivial` (typo, comment, formatting, single-line rename) or `non-trivial` (behavior, API, boundary, or multi-file).
- If `trivial`, MUST NOT expand scope to unrelated structural changes. Flag structural debt with an expiry and owner instead.
- MUST record the decision in one line. Example: `trivial — gated` or `non-trivial — full scan`.

### 2. Check Module Depth and Information Hiding

Apply Ousterhout. A deep module hides significant complexity behind a simple interface. Most knowledge stays internal. Invalid states are unrepresentable.

**Constraints:**

- MUST load `software-architecture` §5 and check: does the change expose a simple interface and hide its implementation. When the interface is as complex as the implementation, the abstraction is shallow and MUST be removed or deepened.
- MUST check information hiding: no caller depends on a callee's internal representation. Vendor types are translated at the edge that contacts the vendor.
- SHOULD define errors out of existence where possible. Prefer a type that makes the error unrepresentable over a function that returns the error.
- MUST check that the new interface has a clean comment. When a concise interface comment is not possible, the design is wrong and the agent returns to this step.
- If a structural issue sits outside `task_scope`, MUST propose the ideal, record debt with a deadline, and proceed. MUST NOT mix a broad refactor into the current change.

### 3. Isolate Side Effects

Separate I/O from logic so the core is testable with values alone.

**Constraints:**

- MUST structure an operation as gather, process, commit. `gather` fetches external state. `process` is a deterministic pure function with no I/O. `commit` persists the result.
- MUST NOT place business logic inside gather or commit.
- MUST keep dependencies in one direction. One bounded context owns one model and translates at the boundary.
- MUST run cheap local validation before remote calls. A transaction wraps only the final commit.

### 4. Apply Effective Go

Polish the function after structure is sound or debt is recorded.

**Constraints:**

- MUST load `go`. Apply it as a checklist.
- MUST enforce in order: guard clauses and left-aligned happy path, then extract method and consolidate conditionals, then naming as abstraction and scope minimization.
- MUST follow Effective Go for Go files: `MixedCaps`, `context.Context` as first argument for I/O, small consumer-defined interfaces, `fmt.Errorf("...: %w", err)` with `errors.Is`/`errors.As`, `defer` close to acquisition, `make` versus `var` made explicit, and `gofmt` layout.
- MUST keep whitespace grouped: blank lines separate logical blocks and top-level declarations. Must keep comments sparse and interface-first.
- MUST NOT introduce novelty that contradicts the three nearby files or the linter config.

### 5. Validate

Confirm that structure precedes tactics and that Go idioms hold.

**Constraints:**

- MUST verify:
  - Scope was gated and recorded.
  - The module is deep. The interface is simple and hides its complexity.
  - Information does not leak across the boundary.
  - I/O is separate from pure logic. The core is testable with values.
  - Guard clauses are present and the happy path is left-aligned.
  - `go` checks pass for `.go` files.
- MUST NOT consider the change complete until all items pass or debt is recorded with an expiry.

## Examples

### Example Input

Add credit-limit check to `CreateOrder`.

### Example Flow

1. Gate: `non-trivial — full scan`. The change adds a business rule across a boundary.
2. Structure: load `software-architecture`. `CreateOrder` mixes a database fetch with credit logic. Extract `ValidateAndBuildOrder(user, req) OrderResult` as pure function. The handler does `user, err := db.GetUser(ctx, req.UserID)` (gather), calls the pure function (process), then `db.SaveOrder(ctx, order)` (commit). Record the old mixed function as deprecated with expiry `2026-09-01`.
3. Tactics: load `go`. Replace nested conditionals with guard clauses, wrap the database error with `%w`, pass `ctx` as first argument, keep the new interface to one method.
4. Validate: all checks pass. Debt has an expiry.

## Troubleshooting

### Scope expands on a trivial fix

Scope gate was skipped. Return to Step 1, reclassify as `trivial — gated`, and record debt instead of refactoring.

### Tactics hide a shallow abstraction

Step 2 was skipped. Re-run the depth check before polishing. A simple rename does not fix an interface that leaks storage details.
