---
name: software-architecture
description: Principles for structuring software. Use when designing or changing module boundaries, public interfaces, dependency direction, or data flow. Do not use for local function polish, completed-diff review, or language-specific syntax.
---

# Software architecture

Structure code to minimize the concepts a maintainer must track. Line count doesn't matter; concept count does.

- **Fewer concepts beats fewer lines.** One term per concept. No speculative flexibility.
- **Interfaces simpler than implementations.** An abstraction must hide complexity, enforce an invariant, or name a domain concept. No thin wrappers or forwarding helpers.
- **Effects at boundaries.** Network, storage, clocks, randomness, and process state live at explicit boundaries. Test decisions with values, not mocks.
- **Parse, don't validate.** Convert untrusted input into a type that represents valid data at the earliest boundary that knows enough to reject it. Make invalid states unrepresentable.
- **Each context owns its model.** Translate vendor, transport, and storage representations at the boundary where they arrive; external schemas never leak inward.
- **Failure policy lives with the dependency.** Retries, timeouts, and circuit breakers sit in the module that owns the dependency; retryable writes are idempotent.
- **Designed for deletion.** Evolve public interfaces additively. Every flag, shim, and deprecated path has an owner and an expiry. Dead code is removed in the same task or recorded as debt with both.

These are defaults. Repository and language conventions override them.
