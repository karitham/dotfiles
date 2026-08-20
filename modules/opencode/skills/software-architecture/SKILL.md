---
name: software-architecture
description: >
  Reference for structuring non-trivial software to minimize total cognitive load and preserve conceptual integrity. The agent uses this reference when designing APIs, adding endpoints, defining module boundaries, structuring services, handling side effects, or deciding what remains public. It covers the impure-pure-impure sandwich, bounded contexts, dataflow and pipeline design, event-driven patterns, resource-aware orchestration, and structural standards that reduce accidental complexity and make deletion one pull request. Keywords: functional core, imperative shell, bounded context, event sourcing, CQRS, data pipeline, idempotency, short-circuiting, sacrificial architecture, deletion, deprecation expiry, total cognitive load, accidental complexity, conceptual integrity. Do NOT use for function-level code style — use code-writing instead.
---

# Software Architecture Protocol

The agent uses this protocol when a decision changes module boundaries, public interfaces, data flow, or dependency direction. The protocol governs structure by one constraint: minimize total cognitive load and preserve conceptual integrity.

Total surface area means the set of modules, interfaces, invariants, and flags the maintainer must hold in head to make a safe change. The agent minimizes that set. The agent prefers clarity over clever optimization. The agent treats the system as sacrificial. The agent assumes that 10x scale will require replacement. Good modularity makes replacement one pull request and not sixty files.

## 0. Continuous Improvement

The agent SHOULD suggest architectural improvements only when directly relevant to the task at hand. The agent MUST NOT lecture on bounded contexts when fixing a typo.

- The agent flags structural debt when encountering it during legitimate work and proposes the ideal shape alongside the pragmatic fix.
- The agent keeps each improvement small and visible. A single well-placed extraction or boundary is better than waiting for a large refactor.
- The agent MUST NOT expand scope outside the current task without an expiry or migration window (see §9). When deletion would require changes outside task scope, the agent flags the debt and proposes the ideal, but defers the deletion.

## 1. Design Protocol

The agent follows this sequence for every architecture decision. The sequence reduces extraneous load before committing to structure.

1. **Identify the boundary.** What is public vs internal? Who calls this? What does it depend on? (Defines surface area.)
2. **Gather constraints.** Latency requirements, consistency needs, failure modes, team ownership, and conceptual integrity of existing concepts.
3. **Propose the simplest structure.** Start with a deep module: simple interface, hidden complexity. Prefer the structure that minimizes total cognitive load.
4. **Check against patterns.** Does the impure-pure-impure sandwich apply? Are bounded contexts clear? Is dataflow linear? Does deletion stay within one pull request?
5. **Flag what the agent cannot fix.** When the current structure violates these principles, the agent suggests the ideal alongside the pragmatic path and records the debt with an expiry.

## 2. Minimize total cognitive load and enable deletion

A maintainer traces a failure with limited prior context. The maintainer follows one map from entry point to failure site. The agent therefore designs every structure so the maintainer holds only one context in head at a time.

The agent SHOULD delete a module, flag, or abstraction when its retention obscures the map and increases extraneous cognitive load, even if the code works. The agent MUST do so only within the scope of the current task or behind a deadline and migration window per §9. When deletion would span outside task scope, the agent MUST flag the debt, propose the ideal, and defer the deletion rather than mixing a broad refactor into the current change. The agent MUST reduce accidental complexity where it impedes conceptual integrity. The agent MUST bound performance work by clarity. The agent SHOULD treat an optimization that obscures the map as a debugging surface with no offsetting benefit and defer the optimization.

Surface area: maintainer tracks one module and its explicit inputs. Deletion: remove one module, flag, or endpoint in one pull request with no other module requiring edits.

BAD: the agent keeps a deprecated adapter because it still works and adds a second adapter for the new path. The codebase now has two adapters, two sets of types, and a routing flag with no expiry.

```go
// two adapters remain, caller chooses at runtime
if useNewAdapter {
    newAdapter.Call(req)
} else {
    oldAdapter.Call(req)
}
```

GOOD: the agent defines a single interface, routes all callers through it, and sets an expiry for the old adapter. The agent translates vendor types at the edge and holds one model in the core. The old adapter disappears in one pull request when the expiry triggers.

```go
// single interface, vendor translation at the edge
type Store interface { Get(id string) (Order, error) }

func NewStore(cfg Config) Store {
    // vendor translation happens here, core sees only Order
    return &pgStore{db: cfg.DB}
}
```

## 3. Isolate side effects with the impure-pure-impure sandwich

Side effects include database access, network calls, clock reads, and ID generation. Business logic includes validation, calculation, and state transitions. The protocol separates the two.

Surface area: maintainer tests business logic with values alone, without holding database or network state in head. Deletion: agent replaces the gather or commit step without touching the pure core.

The agent MUST structure an operation as gather, process, commit. The gather step fetches external state. The process step runs a deterministic pure function that performs no I/O and accesses no global state. The commit step persists the result. The agent MUST NOT place business logic inside the gather or commit steps, because that placement would hide a decision inside I/O and increase surface area.

BAD: logic mixes with I/O. The caller cannot test the credit rule without a database. The function also holds a transaction while it computes.

```go
func CreateOrder(db *sql.DB, req OrderRequest) error {
    user, _ := db.GetUser(req.UserID)
    if user.Suspended { return ErrSuspended }
    total := calcTotal(req.Items)
    if total > user.CreditLimit { return ErrOverLimit }
    return db.SaveOrder(Order{UserID: user.ID, Items: req.Items, Total: total})
}
```

GOOD: the handler gathers, the pure function decides, the handler commits. The logic is testable with values. The transaction covers only the final write.

```go
func CreateOrderHandler(db *sql.DB, req OrderRequest) error {
    user, err := db.GetUser(req.UserID)
    if err != nil { return err }
    result := ValidateAndBuildOrder(user, req)
    if result.Err != nil { return result.Err }
    return db.SaveOrder(result.Order)
}

func ValidateAndBuildOrder(user User, req OrderRequest) OrderResult {
    if user.Suspended { return OrderResult{Err: ErrSuspended} }
    total := calcTotal(req.Items)
    if total > user.CreditLimit { return OrderResult{Err: ErrOverLimit} }
    return OrderResult{Order: Order{UserID: user.ID, Items: req.Items, Total: total}}
}
```

## 4. Enforce bounded contexts with one-direction dependencies

A bounded context defines one model that applies within one ownership boundary. The same real concept may have different models in different contexts. The agent owns each model inside its context.

Surface area: maintainer reasons about one model at a time without reconciling conflicting definitions. Deletion: agent deletes a context by removing its model and translation layer; other contexts stay unchanged because dependencies point one way.

The agent MUST give each module or service its own model. The agent MUST translate between contexts at the boundary. The agent MUST keep imports in one direction. The agent MUST NOT share a model across contexts, because sharing would couple callers to implementation details and spread edits across many files. The agent MUST translate vendor types at the edge, at the module that contacts the vendor. The core must see only internal types.

BAD: two contexts share a vendor type. Deletion of the vendor requires edits in every context.

```go
// shared vendor type leaks into core
type Order = stripe.Order  // core now depends on stripe
func Charge(o stripe.Order) error { ... }
```

GOOD: each context defines its own type. The boundary translates.

```go
// core defines its own type
type Order struct { ID string; Total int }

// edge translates vendor type to core type
func toCore(s stripe.Order) Order { return Order{ID: s.ID, Total: s.Amount} }
func Charge(o Order) error { ... }
```

## 5. Design deep modules that hide information

A deep module exposes a simple interface and retains significant complexity internally. A shallow module exposes an interface as complex as its implementation and adds indirection with no abstraction.

Surface area: maintainer learns one simple interface, not hidden details. Deletion: agent removes a deep module by deleting its interface and internals together; callers depend only on the interface, so scope stays bounded.

The agent MUST hide complexity behind the interface. The agent SHOULD remove a shallow abstraction when the interface does not simplify use. The agent SHOULD keep resilience handling inside the module that owns the dependency, so callers do not hold retry or breaker state in head.

### Information Hiding

The agent MUST ensure most knowledge of a module is internal and invisible to callers. When information leaks across boundaries, every caller couples to implementation details.

### Deep Modules

The agent MUST design modules to be deep: simple interfaces hiding significant complexity. The agent SHOULD design the interface first; if the interface is hard to describe, the abstraction is shallow.

### State Integrity

The agent MUST enforce invariants via the type system. Invalid states SHOULD be unrepresentable. The type checker then catches misuse before review.

BAD: the interface exposes internal storage details. Callers must handle invariants and retry policy.

```go
type OrderStore struct { DB *sql.DB }
func (s *OrderStore) GetOrderRow(id string) (Row, error) // row mirrors table
// caller validates, retries, and interprets row
```

GOOD: the interface hides storage and enforces invariants. The type prevents an invalid order.

```go
type OrderID string
type OrderStore interface { Get(id OrderID) (Order, error) }
// Order is always valid by construction, retry lives inside the store
```

Resilience detail: the module that calls an external service owns retries with backoff, circuit breaker, and bulkhead isolation. The caller sees only a result or an error. This placement keeps failure handling out of the maintainer's head.

### API Backward Compatibility

The agent MUST evolve public APIs additively. The agent adds optional fields or new endpoints. The agent MUST NOT break consumers without a migration window. Deprecation requires a migration window, not an immediate breaking change.

## 6. Model systems as dataflow pipelines with idempotent steps

The agent models a system as a pipeline that transforms data step by step. Each step takes data, transforms it, and passes it forward.

Surface area: maintainer follows one linear pipeline, not unordered callbacks or hidden shared state. Deletion: agent deletes a step and reconnects input to output; other steps stay unchanged. Derived data regenerates from the source, so the agent can delete a cache or materialized view and rebuild it.

The agent MUST design writes to be idempotent where possible, so retries remain safe. The agent MUST treat derived data as reproducible from the source of truth. The agent SHOULD model each step as a pure transform where feasible, so the pipeline composes from testable functions.

BAD: a step mutates shared state and a write fails on retry because it appends again.

```go
func ApplyPayment(orderID string, amount int) error {
    // not idempotent: second call double-applies
    return db.Exec("UPDATE orders SET total = total + ? WHERE id = ?", amount, orderID)
}
```

GOOD: the step uses an idempotency key and a deterministic transform. A retry produces the same result. Error handling omitted for brevity is handled per code-writing: validate at boundaries, return errors, do not swallow.

```go
func ApplyPayment(tx *sql.Tx, key string, orderID string, amount int) error {
    var done bool
    if err := tx.QueryRow("SELECT exists(SELECT 1 FROM payments WHERE key=?)", key).Scan(&done); err != nil {
        return err
    }
    if done { return nil }
    if _, err := tx.Exec("INSERT INTO payments(key, order_id, amount) VALUES(?,?,?)", key, orderID, amount); err != nil {
        return err
    }
    return nil
}
```

## 7. Decouple in time with event-driven patterns

Events decouple producers from consumers. The log orders facts. Projections derive current state.

Surface area: maintainer reasons about what happened, not which consumer called which producer when. Deletion: agent adds or removes a consumer without touching the producer; agent deletes a projection and rebuilds it from the log.

The agent MUST describe events as facts about what happened, not as commands about what to do. The agent MUST separate read and write models when their scaling or consistency needs diverge. The agent MUST NOT rely on event order unless the system guarantees order.

BAD: a producer calls consumers directly and sends a command. Every new consumer changes the producer.

```go
func OnOrderCreated(o Order) {
    email.SendOrderEmail(o)   // producer knows consumer
    inventory.Reserve(o)      // deletion touches producer
}
```

GOOD: the producer appends a fact. Consumers project from the log. Deletion removes a consumer alone.

```go
func OnOrderCreated(o Order) error {
    return log.Append(Event{Type: "order.created", OrderID: o.ID, Total: o.Total})
}
// consumer subscribes independently
func ProjectEmail(events <-chan Event) { for e := range events { if e.Type == "order.created" { email.Send(e) } } }
```

## 8. Order operations to minimize expensive surface area

Expensive means high latency, locking, or coupling. Cheap means local and deterministic.

Surface area: maintainer holds cheap checks first and holds expensive state only at the end; a trace fails fast on a local check and avoids deep state. Deletion: agent removes an expensive check by deleting one precondition before the commit without changing transaction scope.

The agent MUST short-circuit. The agent runs cheap local validation before remote calls. The agent MUST minimize lock scope. The agent wraps only the final commit in a transaction. The agent MUST NOT hold a transaction while it calls a remote service, because that hold would block other work and force the maintainer to reason about lock duration. The agent SHOULD pass raw data to business logic and avoid behavioral interfaces, because interfaces would couple logic to I/O and enlarge surface area.

BAD: the operation opens a transaction, then validates locally, then calls a remote service while the transaction blocks.

```go
tx.Begin()
user := db.GetUser(tx, req.UserID)
if user.Suspended { tx.Rollback(); return ErrSuspended }
resp := payment.Verify(user) // remote call while tx holds locks
tx.Commit()
```

GOOD: cheap checks first, one-direction data flow, transaction only for the final commit. Pure functions use guard clauses per code-writing: early return, happy path left-aligned.

```go
if req.UserID == "" { return ErrInvalid }
user, err := db.GetUser(req.UserID)
if err != nil { return err }
if user.Suspended { return ErrSuspended }
if err := payment.Verify(user); err != nil { return err }
tx.Begin()
defer tx.Rollback()
if err := db.SaveOrder(tx, order); err != nil { return err }
if err := tx.Commit(); err != nil { return err }
return nil
```

## 9. Make obsolescence enforceable and celebrate deletion

Deprecation without enforcement never finishes. A flag or endpoint without an expiry spreads logic across files and expands surface area.

Surface area: maintainer sees only current paths; expired paths are gone, not branched. Deletion: agent removes a deprecated path in one pull request when the deadline arrives, because the agent isolated the path behind a deep boundary and tracked it with tooling.

The agent MUST attach a deadline to every temporary seam: flags, TODOs, deprecated fields, and compatibility shims. The agent MUST provide migration tooling and define an enforcement mechanism before it merges the seam. The agent MUST prevent backslide. Backslide prevention includes lint rules that reject new uses of deprecated symbols and build visibility whitelists that block new imports. The agent SHOULD treat a pure-deletion pull request as the ideal outcome and track such deletions.

The agent MUST evolve public APIs additively. The agent adds optional fields or new endpoints. The agent MUST NOT break consumers without a migration window.

BAD: a flag has no deadline and no lint. Callers multiply, and deletion requires hunting across the codebase.

```go
// flag without expiry, no tracking
if featureFlag("new_checkout") { checkoutV2() } else { checkoutV1() }
```

GOOD: the flag has a deadline, an owner, and CI that fails on new uses after deprecation.

```go
// flag with deadline 2026-12-01, owner @checkout-team
// lint: forbid new uses of FlagNewCheckout after 2026-06-01
// CI enforces the rule, migration tool rewrites callers
if flag.Enabled(ctx, FlagNewCheckout) {
    checkoutV2() // path to delete in one PR on expiry
} else {
    checkoutV1()
}
```

At every seam the agent determines the scope of failure if that dependency disappears tomorrow. The agent bounds the scope to one module through one-direction deps and edge translation. Performance work stays bounded by clarity: the agent chooses the clear path when a faster path would obscure the map and would add debugging surface with no offsetting benefit.

## 10. Refine structure through small continuous improvements

The agent does not wait for a large refactor. The agent improves structure where the agent touches code.

Surface area: small improvements keep the map accurate and prevent drift that would force relearning. Deletion: each small improvement creates a boundary that then allows deletion in one pull request later.

The agent SHOULD flag structural debt when it meets it during legitimate work and propose the ideal shape beside the pragmatic fix. The agent SHOULD apply the refactoring pattern: identify hidden side effects such as clock reads, lift I/O to the caller, convert the remaining logic to a pure function, and verify that the core needs no mocks and uses guard clauses per code-writing. The agent MUST keep each improvement small and visible.

BAD: the agent mixes a feature with a broad refactor in one change. The diff touches many contexts and hides the logic change.

GOOD: the agent adds the feature with minimal structure, then follows with a focused cleanup that extracts one pure function and moves one I/O call to the boundary.

---

## Validation Checklist

- [ ] Sandwich: does a clear line separate I/O from logic, so the maintainer tests logic with values alone
- [ ] Purity: does business logic take only data and return a Result, with no I/O interface
- [ ] Ordering: does the operation short-circuit with cheap checks, and does a transaction wrap only the final commit
- [ ] Boundaries: does each context own its model, do imports point in one direction, and does vendor translation sit at the edge
- [ ] Idempotency: can the agent safely retry each write
- [ ] Depth: does the module expose a simple interface and hide its implementation
- [ ] State Integrity: does the type make an invalid state unrepresentable
- [ ] API Compatibility: does the change evolve APIs additively with a migration window, not a breaking change
- [ ] Types: are primitives replaced where a domain type would prevent a bug
- [ ] Mocks: can the agent test the core with value assertions and no mock framework
- [ ] Code Style: do pure functions use guard clauses and left-aligned happy path per code-writing
- [ ] Resilience: does the owning module contain retries and breakers, so callers stay simple
- [ ] Obsolescence: does every flag, TODO, and deprecated symbol have a deadline, migration path, and lint or build rule that blocks new uses
- [ ] Deletion and Cognitive Load: can the maintainer understand the map while holding one module in head, and can the agent delete the feature or module in one pull request with bounded failure scope

## References

- Ousterhout, J. *A Philosophy of Software Design* (deep modules, information hiding)
- Evans, E. *Domain-Driven Design* (bounded contexts)
- Kleppmann, M. *Designing Data-Intensive Applications* (dataflow, derived data, event sourcing)
- Brooks, F. *The Mythical Man-Month* (conceptual integrity) and *No Silver Bullet* (accidental vs essential complexity)
- Sweller, J. *Cognitive Load Theory* (total cognitive load: intrinsic, germane, extraneous)
- Campbell, G. *Cognitive Complexity* (understandability metric)
- Google. *Software Engineering at Google*, ch. 15 (obsolescence)
- Fowler, M. *Sacrificial Architecture* (design for replacement)
- Plain Technical Prose §Sentence mechanics for register and sentence mechanics
