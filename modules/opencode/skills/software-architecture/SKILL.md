---
name: software-architecture
description: >
  Technical protocol for designing and refactoring non-trivial software. Focuses on the Impure-Pure-Impure sandwich, lifting I/O, and resource-aware orchestration. Use when the user asks to "design a component," "structure code," "refactor a service," or "handle side effects." Keywords: functional core, imperative shell, dependency rejection, deep modules, short-circuiting.
---

# Software Architecture Protocol

This skill provides a systematic framework for managing complexity and side effects in software systems.

## 1. The "Impure-Pure-Impure" Sandwich Pattern

All non-trivial operations MUST follow this sequential workflow to isolate side effects from business logic.

### Workflow

1.  **Gather (Impure Boundary):** Fetch all external state required for the decision.
    - _Examples:_ DB queries, API calls, reading system time, generating UUIDs.
2.  **Process (Functional Core):** Pass the gathered data into a pure function.
    - _Constraint:_ This function MUST be deterministic. It MUST NOT perform I/O or access global state. It MUST return data or a "Result" struct.
3.  **Commit (Impure Boundary):** Persist the output of the Functional Core.
    - _Examples:_ DB writes, sending HTTP responses, logging.

## 2. Resource-Aware Orchestration

Operations MUST be ordered to minimize the surface area of high-latency or locking operations.

- **Short-Circuiting:** Cheap local checks (logic/time guards) MUST occur before expensive remote checks (Network/API).
- **Lock Minimization:** Database transactions (`WithTx`) SHOULD only wrap the final "Commit" phase.
- **Dependency Rejection:** Business logic SHOULD accept raw data structures (e.g., `[]int`) rather than behavioral interfaces (e.g., `UserStore`) to avoid unnecessary "Interface Soup."

## 3. Structural Standards

### Module Depth (Ousterhout's Principle)

- Modules MUST be "Deep": simple interfaces hiding significant internal complexity.
- If an interface is as complex as its implementation, the abstraction SHOULD be removed (Compression-Oriented Design).

### State Integrity (Parse, Don't Validate)

- Invariants MUST be enforced via the type system (e.g., `NewUserID(string)` vs a raw `string`).
- Invalid states SHOULD be unrepresentable. Use Enums/Sum types instead of multiple dependent Booleans.

## 4. Feedback Loop: Refactoring Pattern

When refactoring existing code to this standard:

1.  **Identify Side Effects:** Find all hidden I/O (e.g., `time.Now()`, `db.Get`).
2.  **Lift I/O:** Move those calls to the caller or the entry point of the function.
3.  **Purify:** Convert the remaining logic into a pure function that accepts the lifted data as parameters.
4.  **Verify:** The core logic MUST be unit-testable without a mocking framework.

---

## Validation Checklist

- [ ] **Sandwich:** Is there a clear line where I/O ends and logic begins?
- [ ] **Purity:** Does any business logic function take a `Context` or an interface that performs I/O? (It shouldn't).
- [ ] **Ordering:** Are network calls happening inside a database transaction? (They shouldn't).
- [ ] **Guard Clauses:** Is the code calling an external API before checking simple local requirements?
- [ ] **Types:** Are we using primitives where a domain-specific type could prevent a bug?
- [ ] **Mocks:** Can this logic be tested with simple value assertions?
