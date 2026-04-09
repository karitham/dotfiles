---
name: code-writing
description: >
  Enforces clean coding conventions for any implementation task. Covers guard
  clauses, extract method, immutability, define errors out of existence, naming,
  and comment-driven development. Use when writing, editing, fixing,
  implementing, or reviewing code at the function or file level. Do NOT use for
  API design, module boundaries, or service structure — use
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

## Immutability

Prefer immutable data. When a value does not change after construction, the
reader can trust it forever. Mutable state forces the reader to track every
assignment.

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

BAD:

    func divide(a, b float64) (float64, error) {
        if b == 0 {
            return 0, ErrDivisionByZero
        }
        return a / b, nil
    }

GOOD:

    type Ratio struct {
        Numerator   float64
        Denominator NonZeroFloat
    }

    func (r Ratio) Value() float64 {
        return r.Numerator / r.Denominator.Value()
    }

- SHOULD design APIs where error cases are unrepresentable
- MUST NOT propagate errors that could be eliminated by better design
- SHOULD use sum types / enums instead of multiple dependent booleans

## Comments

Comments exist to capture information that cannot be expressed in code. If a
comment only restates what the code already says, it MUST be deleted.

### What to comment

Comments MUST describe things that are not obvious from the code:

- Why a decision was made, not what the code does
- Units, valid ranges, and data formats
- Preconditions and postconditions
- Invariants and non-obvious side effects
- Edge cases and their handling rationale

### Interface comments

Interface comments (on classes, functions, and modules) MUST describe the
abstraction — what it does and how to use it — NOT how it is implemented.

A minimal interface comment SHOULD include:

- Purpose: one sentence describing what this does
- Parameters: names, types, and constraints
- Returns: what is returned and when
- Errors: what can go wrong and why

### Implementation comments

Implementation comments SHOULD only appear when the code itself cannot express
the intent clearly. If an implementation comment is needed to explain what the
code does, the code SHOULD be simplified instead.

### Comment-driven development

Interface comments MUST be written before implementation. Writing the comment
first forces clear thinking about the abstraction before committing to code.

If a clean, concise comment cannot be written for a function or module, the
design is likely wrong. Treat the difficulty of commenting as a design smell.

Uncommented public interfaces MUST be treated as incomplete, not finished.

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

MUST match the project's existing style. To discover style conventions:

- Read 3 nearby files before writing
- Check linter config (e.g., `.golangci.yml`, `eslint.config.js`, `ruff.toml`)
- Look for a style guide in AGENTS.md or CONTRIBUTING.md

MUST NOT introduce novelty without reason.

## Read Before Write

MUST read a file before editing it. Blind edits create duplicates and break
subtle invariants.
