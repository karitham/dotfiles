---
name: software-architecture
description: Load BEFORE implementing new features, refactoring, adding abstractions, writing RFCs/architecture docs, or any non-trivial code changes. Skip for simple bugfixes, typo fixes, or one-liners.
---

## Deep Modules

Hide complexity behind simple interfaces. A module's value is what it hides, not what it exposes.

- Interface should be smaller than implementation
- Users shouldn't need to understand internals
- If callers must understand your code to use it, the abstraction has failed
- Prefer few powerful primitives over many specific ones

## Small Interfaces

Minimize surface area. Every public thing is a commitment.

- Fewer parameters, fewer methods, fewer exports
- What isn't exposed can be changed freely
- When in doubt, hide it
- Seal internal details: unexported types, private fields, package-internal functions

## Testability

Design for testing from the start. Untestable design is often poor design.

- Pure functions over stateful objects where possible
- Inject dependencies, don't reach for globals
- Side effects at boundaries; keep core logic pure
- If it's hard to test, consider: wrong abstraction, too many responsibilities, hidden dependencies

## Data & Reliability

From DDIA: systems fail in unexpected ways. Design for failure.

- Assume components will crash, networks will partition, disks will fill
- Prefer immutable data and append-only structures
- Make invariants explicit and enforce them at boundaries
- Think about consistency guarantees upfront—eventual vs strong vs none
- Schema changes should be backward and forward compatible

## Make Illegal States Unrepresentable

Parse, don't validate. Transform input into types that guarantee invariants.

- If a value exists, it's valid—no downstream checks needed
- Use sum types, newtypes, and enums to constrain possible values
- Bad states should be compiler errors, not runtime bugs
- Example: `PositiveInt` not `int` with a check; `Pending | Approved | Rejected` not `string status`

## Fail Fast at Boundaries

Validate at system edges, assume valid inside.

- Reject bad input immediately with clear errors
- Don't propagate garbage deeper into the system
- Boundaries: API handlers, CLI args, file parsers, external service responses
- Once past the boundary, code can trust the data

## Design It Twice

Before implementing, explore at least two approaches.

- First idea is rarely the best—bias toward familiar patterns
- Sketch alternatives, compare tradeoffs
- Consider: complexity, performance, extensibility, testability
- Pick the simplest one that solves the real problem

## Coupling & Cohesion

- High cohesion: things that change together, stay together
- Low coupling: modules should not know about each other's internals
- Avoid circular dependencies
- One responsibility per module—if you can't summarize it in one sentence, split it

## Before You Code

1. What changes and what stays the same? Put them in different places.
2. What's the simplest interface that covers the use case?
3. What can go wrong? How does the system recover?
4. How would you test this?
5. What will be hard to change later? Make that explicit.
