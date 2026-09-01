---
name: software-design
description: Provides principles for designing and revising software from function scope through system boundaries. Covers cognitive load, deep modules, functional cores, control flow, state, bounded contexts, data flow, compatibility, and deletion. Use when implementing, refactoring, or designing code, APIs, modules, and services. Do NOT use as the primary workflow for unexplained failures, completed-diff review, or language-specific syntax.
---

# Software design

Software design communicates behavior and intent to maintainers while providing instructions to a machine. The agent minimizes the concepts that a maintainer must track. Line count is not the objective.

Repository conventions and language-specific skills refine these principles. They do not replace them.

## Cognitive load and conceptual integrity

Brooks's conceptual-integrity principle requires one coherent model of the system. Essential complexity remains. Accidental complexity does not.

- MUST prefer fewer concepts when two designs satisfy the same requirements.
- MUST separate conceptually unrelated concerns instead of entangling them to reduce line count.
- MUST preserve one term and one model for each concept within a context.
- SHOULD choose clear code over a clever optimization until measurements justify the additional complexity.
- MUST NOT add speculative flexibility, because unused extension points increase the surface that maintainers must understand.

## Deep modules and information hiding

Ousterhout's deep-module principle requires a simple interface that hides substantial implementation complexity.

- MUST keep an interface simpler than the implementation it hides.
- MUST keep implementation knowledge inside the module that owns it.
- MUST introduce an abstraction only when it hides complexity, enforces an invariant, or names a domain concept.
- MUST NOT add a thin wrapper, forwarding helper, or class around a simple data structure, because an unchanged interface leaves the caller with the same concepts and adds indirection.
- SHOULD minimize public interfaces. Every export creates a compatibility commitment.
- SHOULD group parameters only when they form one domain concept.
- SHOULD extract a function when the function owns a separate responsibility or its name removes a concept from the caller.
- MUST NOT extract a function only because it is short, because indirection has a reading cost.

## Functional core, imperative shell

The functional-core, imperative-shell pattern keeps decisions in pure functions and effects at system boundaries.

- SHOULD structure an operation as gather, process, commit.
- MUST keep business rules in deterministic functions that accept values and return values.
- MUST keep network calls, storage, clocks, randomness, and process state at explicit boundaries.
- MUST NOT hide business decisions inside I/O code, because tests and callers cannot observe the decision independently of the effect.
- SHOULD test core logic with values and without mocks.
- SHOULD prefer immutable values when they reduce the state that a maintainer must track.
- MAY use mutation when it is simpler. The mutation MUST have one owner, remain local, and preserve an explicit invariant.
- SHOULD use an explicit state machine when transitions would otherwise depend on scattered mutable flags.

## Control flow and data flow

The happy path SHOULD live on the left. Guard clauses remove errors and edge cases before the main operation.

- MUST return or fail early on invalid input and edge cases when the language permits it.
- MUST NOT add an `else` after a terminating branch, because the `else` only adds nesting.
- SHOULD model processing as a linear pipeline of explicit transformations.
- SHOULD name a predicate when several conditions express one domain decision.
- MUST NOT combine unrelated conditions behind one predicate, because the name would hide separate decisions.
- MUST run cheap local checks before expensive or remote work.
- MUST keep transaction scope as small as consistency permits.
- MUST NOT call a remote service while holding a transaction, because remote latency extends lock duration and failure scope.

## Boundaries and domain models

Evans's bounded-context principle gives each context one model and one owner. Dependencies cross a boundary in one direction.

- MUST define domain types inside the context that owns their meaning.
- MUST translate vendor, transport, and storage representations at the boundary that receives them.
- MUST NOT leak an external representation into the core model, because external changes would spread through unrelated code.
- MUST validate input at the earliest boundary that has enough information to reject it.
- SHOULD follow "parse, don't validate": convert untrusted input into a type that represents validated data, then pass that type inward.
- SHOULD make invalid states unrepresentable with constructors, enums, sum types, and constrained values.
- MUST use parameterized queries for database input.
- MUST load credentials from the approved configuration or secret store.
- MUST NOT include credentials in source, logs, errors, or fixtures, because each output creates another disclosure path.

## Errors, retries, and concurrency

Errors form part of an interface. The owner of an external dependency also owns its failure policy.

- MUST expose failures through the local language and repository convention.
- MUST preserve the cause and operation when adding error context.
- MUST NOT swallow an error or replace it with an uninformative failure, because callers need the cause to recover or diagnose the operation.
- MUST NOT crash on invalid external input when the runtime provides a recoverable error mechanism, because the caller can handle the failure.
- MUST keep retries, timeouts, backoff, circuit breakers, and concurrency limits inside the module that owns the dependency.
- MUST make retryable writes idempotent or guard them with an idempotency key.
- MUST give shared mutable state one owner and explicit synchronization.
- MUST give concurrent work a cancellation and shutdown path.

## Data and events

Dataflow systems remain understandable when each step has explicit input and output.

- SHOULD model each processing step as a pure transformation where practical.
- MUST keep a source of truth distinct from derived data.
- SHOULD make derived data reproducible from its source.
- MUST describe events as facts that happened, not commands for a consumer.
- MUST NOT depend on event order unless the transport guarantees that order, because delivery can reorder concurrent events.
- SHOULD separate read and write models only when their consistency, query, or scaling requirements differ.

## Compatibility, obsolescence, and deletion

Fowler's sacrificial-architecture principle treats replacement as an expected outcome. A removable module does not require edits throughout the system.

- MUST evolve public interfaces additively unless callers have an explicit migration window.
- MUST give every temporary flag, compatibility shim, deprecated symbol, and TODO an owner and expiry.
- MUST define a migration path and an enforcement mechanism for each deprecated path.
- SHOULD design a feature so its code and configuration can be deleted in one pull request.
- MUST remove dead code and completed compatibility paths, because inactive paths still increase cognitive load.
- MUST keep improvements inside the current task scope.
- MUST record relevant structural debt with an owner and expiry when the task cannot contain the ideal change.

## Names, comments, and local conventions

Names provide abstractions. Comments record contracts, invariants, and reasons that code cannot express.

- MUST name what a value or operation means rather than how it currently works.
- MUST NOT use a name that hides a side effect or a second responsibility, because callers would rely on an incomplete contract.
- MUST describe purpose, inputs, outputs, and failures in public interface comments when the repository uses them.
- MUST NOT write an implementation comment that repeats the code, because duplicate descriptions drift apart.
- SHOULD write a public interface comment before its implementation. An interface that cannot be explained concisely requires more design work.
- SHOULD simplify code when a comment is required to explain what the code does.
- MUST declare local variables near their first use and keep them in the narrowest useful scope.
- MUST read the target file before editing it.
- MUST read nearby examples, local instructions, and formatter, linter, and test configuration before introducing a new pattern.
- MUST follow local conventions unless the task explicitly changes them.

## Design check

Before implementation or review, verify:

- The design contains no concept that lacks a current requirement.
- Each abstraction removes more complexity than it adds.
- Pure logic and side effects have an explicit boundary.
- Control flow exposes the happy path and failure paths.
- Each context owns its model and translates external representations at its boundary.
- Errors, retries, mutation, and concurrent work have explicit owners.
- Public changes have a compatibility and deletion plan.
- The implementation follows local and language-specific conventions.

## References

- Fred Brooks, The Mythical Man-Month and No Silver Bullet: conceptual integrity and accidental complexity.
- John Ousterhout, A Philosophy of Software Design: deep modules, information hiding, and errors defined out of existence.
- Gary Bernhardt, Boundaries: functional core and imperative shell.
- Eric Evans, Domain-Driven Design: bounded contexts and domain models.
- Martin Kleppmann, Designing Data-Intensive Applications: dataflow, derived data, events, and idempotency.
- Alexis King, Parse, Don't Validate: boundary parsing and valid internal representations.
- Martin Fowler, Sacrificial Architecture: replacement and deletion.
