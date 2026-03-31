---
name: code-writing
description: Enforces clean coding conventions for any implementation task. Covers guard clauses and early returns, happy-path left-alignment, pure functions separated from I/O, hexagonal architecture, error handling without panics, input validation at boundaries, parameterized queries, no hardcoded secrets, removing dead code, matching existing project patterns, and keeping functions small and single-responsibility. Use when writing new code, refactoring, fixing bugs, or reviewing code for quality.
---

## Guard Clauses

Fowler, _Refactoring_: "Replace Nested Conditional with Guard Clauses"

Exit early on error or edge cases. No `else` after a return.

BAD:

    if valid(input) {
        if hasPermission(user) {
            return doWork(input)
        } else {
            return Err(PermissionDenied)
        }
    } else {
        return Err(InvalidInput)
    }

GOOD:

    if !valid(input) {
        return Err(InvalidInput)
    }
    if !hasPermission(user) {
        return Err(PermissionDenied)
    }
    return doWork(input)

## Happy Path Left-Aligned

The main logic flows downward at the same indentation. Error cases exit early.

- MUST align happy path at the left margin
- MUST return on edge cases before the main work
- Good code reads top-to-bottom without jumping between branches

## Pure Functions Preferred

Evans, _Domain-Driven Design_: Domain logic should not depend on infrastructure.

- SHOULD separate I/O from computation
- SHOULD push effects to function boundaries
- MUST NOT mix database calls, HTTP requests, or file I/O with business logic
  in the same function, because this makes the logic harder to test and reason
  about in isolation.

## I/O at Edges

Cockburn, Hexagonal Architecture: Core logic in the center, adapters at the edges.

- **Edge layer**: handlers, CLI, HTTP - performs I/O, calls core
- **Core layer**: pure functions, business rules - no I/O, testable in isolation

## Read Before Write

MUST read a file before editing it. Blind edits create duplicates, miss context,
and break subtle invariants.

## Error Handling

MUST NOT panic or crash on bad input, because panics bypass error handling and
make recovery impossible. Return errors, validate boundaries, fail gracefully.

## Security

- MUST validate inputs at system boundaries
- MUST use parameterized queries - MUST NOT use string interpolation for SQL,
  because this creates SQL injection vulnerabilities.
- MUST NOT hardcode secrets or credentials, because secrets in source code are
  leaked through version control and code sharing.

## No Dead Code

MUST remove or complete incomplete code. Half-written branches and unused imports
create confusion because readers cannot distinguish between intentional partial
implementations and abandoned work.

## Familiar Code

MUST write code that is familiar to other writers of the codebase.

- Reuse existing patterns
- Match the project's style
- MUST NOT introduce novelty without reason, because unfamiliar patterns slow
  down readers and increase maintenance burden.

## Small Functions

MUST keep functions short and focused on a single responsibility. If a function
does two things, split it.
