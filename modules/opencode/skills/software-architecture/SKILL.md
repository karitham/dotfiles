---
name: software-architecture
description: Load BEFORE any non-trivial design work. Triggers: "design", "architecture", "design the API", "how should this work". Skip for one-liners and typo fixes.
---

## Deep Modules

Hide complexity behind simple interfaces. A module's value is what it hides, not what it exposes.

- Interface SHOULD be smaller than implementation
- Users SHOULD NOT need to understand internals
- If callers MUST understand your code to use it, the abstraction has failed
- SHOULD prefer few powerful primitives over many specific ones

## Small Interfaces

Minimize surface area. Every public thing is a commitment.

- Fewer parameters, fewer methods, fewer exports
- What isn't exposed can be changed freely
- When in doubt, hide it
- MUST seal internal details: unexported types, private fields, package-internal functions

## Make Illegal States Unrepresentable

Parse, don't validate. Transform input into types that guarantee invariants.

- If a value exists, it's valid—no downstream checks needed
- SHOULD use sum types, newtypes, and enums to constrain possible values
- Bad states SHOULD be compiler errors, not runtime bugs
- Example: `PositiveInt` not `int` with a check; `Pending | Approved | Rejected` not `string status`

## Fail Fast at Boundaries

Validate at system edges, assume valid inside.

- MUST reject bad input immediately with clear errors
- MUST NOT propagate garbage deeper into the system
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
- Low coupling: modules MUST NOT know about each other's internals
- MUST avoid circular dependencies
- One responsibility per module—if you can't summarize it in one sentence, split it

## Compression-Oriented Design

Write the direct solution first without abstracting. After the code exists, look for repeated _shapes_ of logic.

- An abstraction is only valid if it reduces total code
- Do not recognize a pattern from elsewhere and apply it to the current problem
- Interfaces SHOULD be general-purpose rather than special-purpose—but do not design general-purpose interfaces upfront

## Before You Code

1. What changes and what stays the same? Put them in different places.
2. What's the simplest interface that covers the use case?
3. What can go wrong? How does the system recover?
4. How would you test this?
5. Will this be testable?
6. What will be hard to change later? Make that explicit.
