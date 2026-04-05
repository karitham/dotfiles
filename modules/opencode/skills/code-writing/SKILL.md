---
name: code-writing
description: >
  Enforces clean coding conventions for any implementation task. Covers guard
  clauses, extract method, pure functions, immutability, define errors out of
  existence, and interface comments before implementation. Use when writing,
  editing, fixing, implementing, or reviewing code at the function or file level.
  Do NOT use for API design, module boundaries, or service structure — use
  software-architecture instead.
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

## Extract Method

Fowler, _Refactoring_: "Extract Method" when a fragment of code needs a name to
explain its purpose, or when the fragment is too long to read at a glance.

- If a function does two things, split it.
- If a block of code needs a comment to explain what it does, extract it into a
  function whose name replaces the comment.
- Small functions are easier to test, reuse, and reason about.

## Consolidate Conditional Expression

Fowler, _Refactoring_: "Consolidate Conditional Expression"

When a series of conditionals all produce the same result, combine them into a
single conditional with a well-named function. The function name documents the
intent.

BAD:

    if employee.seniority < 2 { return 0 }
    if employee.monthsDisabled > 12 { return 0 }
    if !employee.isPartTime { return 0 }

GOOD:

    if notEligibleForBonus(employee) { return 0 }

## Introduce Parameter Object

Fowler, _Refactoring_: "Introduce Parameter Object"

When a function has too many parameters, or a group of parameters naturally
belong together, replace them with a single object. This reduces parameter count
and makes the grouping explicit.

## Pure Functions Preferred

Evans, _Domain-Driven Design_: Domain logic should not depend on infrastructure.

- SHOULD separate I/O from computation
- SHOULD push effects to function boundaries
- MUST NOT mix database calls, HTTP requests, or file I/O with business logic
  in the same function

## Immutability

Prefer immutable data. When a value does not change after construction, the
reader can trust it forever. Mutable state forces the reader to track every
assignment.

- SHOULD use const/readonly/final where possible
- SHOULD return new values rather than modifying inputs
- MUST NOT mutate shared state without explicit synchronization

## Variable Scope Minimization

Ousterhout, _A Philosophy of Software Design_: Reduce the scope of every
variable to the smallest possible range. The fewer variables visible at any
point, the less the reader must track.

- Declare variables as close to first use as possible
- Prefer narrow scope over reuse across unrelated operations
- A variable used in one block MUST NOT leak to the enclosing function

## Naming as Abstraction

Ousterhout, _A Philosophy of Software Design_: A good name is an abstraction. If
a name eliminates the need for a comment, it has done its job.

- Names MUST describe what, not how
- If a name needs a comment to explain it, the name is wrong
- Single-letter names are acceptable only for loop indices and math conventions

## Define Errors Out of Existence

Ousterhout, _A Philosophy of Software Design_: The best way to handle an
exceptional condition is to redefine the problem so the condition cannot occur.

- SHOULD design APIs where error cases are unrepresentable
- MUST NOT propagate errors that could be eliminated by better design
- SHOULD use sum types / enums instead of multiple dependent booleans

## Interface Comments Before Implementation

Ousterhout, _A Philosophy of Software Design_: Interface comments describe the
abstraction — what it does and how to use it — NOT how it is implemented.

- MUST write interface comments before implementing the function
- If a clean interface comment cannot be written, the design is likely wrong
- Implementation comments MUST only appear when the code cannot express intent

## Error Handling

MUST NOT panic or crash on bad input. Return errors, validate boundaries, fail
gracefully.

## Security

- MUST validate inputs at system boundaries
- MUST use parameterized queries
- MUST NOT hardcode secrets or credentials

## No Dead Code

MUST remove or complete incomplete code. Half-written branches and unused
imports create confusion.

## Familiar Code

MUST match the project's existing style. Reuse existing patterns. MUST NOT
introduce novelty without reason.

## Read Before Write

MUST read a file before editing it. Blind edits create duplicates and break
subtle invariants.
