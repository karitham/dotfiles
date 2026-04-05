---
name: software-architecture
description: >
  Technical protocol for designing and structuring non-trivial software. Covers
  the impure-pure-impure sandwich, bounded contexts, event-driven patterns,
  dataflow modeling, and dependency rejection. Use when designing APIs, adding
  endpoints, defining module boundaries, structuring services, handling side
  effects, or deciding what should be public vs internal. Keywords: functional
  core, imperative shell, bounded context, event sourcing, CQRS, data pipeline,
  idempotency, short-circuiting. Do NOT use for function-level code style or
  refactoring within a single file — use code-writing instead.
---

# Software Architecture Protocol

This skill provides a systematic framework for managing complexity and side
effects in software systems.

## 0. Continuous Improvement

The goal of software architecture is to make the code more resilient to change
over time. You MUST suggest architectural improvements even when you cannot
implement them directly (e.g., out of scope for the current task, too large a
change, or outside the current file).

- Flag architectural debt when you see it, even if you are only fixing a bug.
- Suggest the ideal structure alongside the pragmatic fix.
- Small improvements compound: a single well-placed extraction or boundary is
  better than waiting for a perfect refactor.

## 1. Design Protocol

When approaching any architecture decision, follow this sequence:

1. **Identify the boundary.** What is public vs internal? Who calls this? What
   does it depend on?
2. **Gather constraints.** Latency requirements, consistency needs, failure
   modes, team ownership.
3. **Propose the simplest structure.** Start with a deep module: simple
   interface, hidden complexity.
4. **Check against patterns.** Does the impure-pure-impure sandwich apply? Are
   bounded contexts clear? Is dataflow linear?
5. **Flag what you cannot fix.** If the current structure violates these
   principles, suggest the ideal alongside the pragmatic path.

## 2. The Impure-Pure-Impure Sandwich

All non-trivial operations MUST follow this sequential workflow to isolate side
effects from business logic.

### Workflow

1. **Gather (Impure Boundary):** Fetch all external state required for the
   decision. Examples: DB queries, API calls, reading system time, generating
   UUIDs.
2. **Process (Functional Core):** Pass the gathered data into a pure function.
   This function MUST be deterministic. It MUST NOT perform I/O or access global
   state. It MUST return data or a Result struct.
3. **Commit (Impure Boundary):** Persist the output of the Functional Core.
   Examples: DB writes, sending HTTP responses, logging.

## 3. Bounded Contexts

Evans, _Domain-Driven Design_: A bounded context is a boundary within which a
particular model is defined and applicable.

- Each service or module MUST own its model. Shared models across boundaries
  create coupling.
- The same real-world concept (e.g., "Customer") can have different models in
  different contexts. This is correct, not duplication.
- Translation between contexts happens at the boundary, not in the core.

## 4. Dataflow and Pipelines

Kleppmann, _Designing Data-Intensive Applications_: Think of a system as a
pipeline of data transformations, not as a collection of services calling each
other.

- Each step transforms data and passes it to the next. The pipeline is the
  architecture.
- Idempotent operations allow safe retries and reprocessing. Design every
  write operation to be idempotent where possible.
- Derived data (caches, indexes, materialized views) should be reproducible
  from the source of truth.

## 5. Event-Driven Patterns

Kleppmann, _DDIA_ / Newman, _Building Microservices_: Events decouple producers
from consumers in time and space.

- Event sourcing: persist state changes as a sequence of immutable events. The
  current state is a projection of the event log.
- CQRS: separate read and write models when they have different scaling or
  consistency requirements.
- Consumers MUST NOT assume event ordering unless the system guarantees it.
- Events describe what happened, not what to do. Commands describe what to do.

## 6. Resource-Aware Orchestration

Operations MUST be ordered to minimize the surface area of high-latency or
locking operations.

- **Short-Circuiting:** Cheap local checks MUST occur before expensive remote
  checks.
- **Lock Minimization:** Database transactions SHOULD only wrap the final
  commit phase.
- **Dependency Rejection:** Business logic SHOULD accept raw data structures
  rather than behavioral interfaces to avoid unnecessary coupling.

## 7. Structural Standards

### Information Hiding (Ousterhout)

The primary purpose of a module is to hide complexity. Design modules so that
most of their knowledge is internal and invisible to callers. When information
leaks across boundaries, every caller becomes coupled to implementation details.

### Deep Modules (Ousterhout)

Modules MUST be deep: simple interfaces hiding significant internal complexity.
If an interface is as complex as its implementation, the abstraction SHOULD be
removed.

### State Integrity

Invariants MUST be enforced via the type system. Invalid states SHOULD be
unrepresentable.

### Compression-Oriented Design

Do not abstract prematurely. Extract a shared abstraction only after the second
use case appears and the commonality is clear.

### Database Per Service

Newman, _Building Microservices_: Each service owns its data. No other service
MUST access another service's database directly. Data sharing happens through
APIs or events.

### API Backward Compatibility

Evolve APIs without breaking consumers. Additive changes only (new optional
fields, new endpoints). Deprecation requires a migration window, not an
immediate breaking change.

### Resilience Patterns

Kleppmann, _DDIA_: Services fail. The system must survive.

- Circuit breaker: stop calling a failing service after repeated failures.
- Retry with backoff: transient failures are normal, but retry storms are not.
- Bulkhead isolation: isolate components so failure in one does not cascade.

## 8. Feedback Loop: Refactoring Pattern

When refactoring existing code to this standard:

1. **Identify Side Effects:** Find all hidden I/O (e.g., `time.Now()`,
   `db.Get`).
2. **Lift I/O:** Move those calls to the caller or the entry point of the
   function.
3. **Purify:** Convert the remaining logic into a pure function that accepts
   the lifted data as parameters.
4. **Verify:** The core logic MUST be unit-testable without a mocking framework.

---

## Validation Checklist

- [ ] **Sandwich:** Is there a clear line where I/O ends and logic begins?
- [ ] **Purity:** Does any business logic function take a Context or an
  interface that performs I/O? (It shouldn't.)
- [ ] **Ordering:** Are network calls happening inside a database transaction?
  (They shouldn't.)
- [ ] **Boundaries:** Does each module own its model, or is there a shared
  model leaking across contexts?
- [ ] **Idempotency:** Can writes be safely retried?
- [ ] **Depth:** Is the module deep, or is it a pass-through adding no
  abstraction?
- [ ] **Types:** Are we using primitives where a domain-specific type could
  prevent a bug?
- [ ] **Mocks:** Can this logic be tested with simple value assertions?
