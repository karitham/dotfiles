---
name: go
description: >
  Reference for idiomatic Go: guard clauses, error handling, context, interfaces,
  concurrency, naming, whitespace, comments, and project layout. Use when writing,
  editing, or reviewing Go code, when the engineering SOP routes a Go file to a
  language-specific check, or when questions about Effective Go or Ousterhout
  design arise. Trigger keywords include go, golang, Effective Go, guard clause,
  and table-driven test.
---

# Go

Idiomatic Go uses explicit error handling, small interfaces, and composition. These principles apply when writing, editing, or reviewing Go code. The engineering SOP loads these principles for Go files.

## Guard Clauses

The happy path stays at the left margin. Error and edge cases return early. No else follows a return.

BAD:

    func LoadConfig(path string) (*Config, error) {
        if path != "" {
            if data, err := os.ReadFile(path); err == nil {
                return parseConfig(data)
            } else {
                return nil, err
            }
        } else {
            return nil, ErrNoPath
        }
    }

GOOD:

    func LoadConfig(path string) (*Config, error) {
        if path == "" {
            return nil, ErrNoPath
        }

        data, err := os.ReadFile(path)
        if err != nil {
            return nil, err
        }

        return parseConfig(data)
    }

- MUST return early on error or edge cases before the main work.
- MUST keep the happy path at the left margin.
- MUST NOT use else after return, because the early return already exits the branch and else adds nesting that obscures flow.

## Errors

The caller decides how to handle an error. The callee returns it with context. Panic signals an unrecoverable programming error, not bad input.

BAD:

    if err != nil {
        return err // loses context
    }
    if err != nil {
        log.Fatal(err) // terminates the process on bad input
    }

GOOD:

    if err != nil {
        return fmt.Errorf("get user %s: %w", id, err)
    }
    if errors.Is(err, ErrNotFound) {
        return ErrInvalidInput
    }

- MUST wrap an error with fmt.Errorf("...: %w", err) when the error crosses a package boundary, because the caller needs context to diagnose the failure.
- MUST use errors.Is and errors.As for sentinel and typed errors, because direct comparison fails on wrapped errors.
- MUST NOT compare error strings with ==, because wrapped errors fail equality checks and messages are not a stable API.
- MUST NOT discard an error with _ without a comment that states the reason, because an ignored error hides a failure.
- MUST NOT panic on bad input, because panic is for unrecoverable programming errors and crashes the process.

## Context

context.Context is the first argument to functions that do I/O, call another context-taking function, or are request-scoped.

BAD:

    func GetUser(id string) (User, error) {
        return db.Query(id)
    }

GOOD:

    func GetUser(ctx context.Context, id string) (User, error) {
        return db.QueryContext(ctx, id)
    }

- MUST take ctx context.Context as the first argument for I/O and request-scoped functions, because cancellation and deadlines propagate through the call tree.
- MUST NOT store Context in a struct, because storage binds the value to a single lifetime and prevents per-call cancellation and makes the owner unclear.
- SHOULD check ctx.Err() or ctx.Done() before expensive work when cancellation matters, because an early check avoids wasted work.

## Interfaces

The consumer defines the interface at the point of use. Interfaces stay small.

BAD:

    type UserService interface {
        GetUser(id string) (User, error)
        SaveUser(u User) error
        DeleteUser(id string) error
        ListUsers() ([]User, error)
    }

GOOD:

    type userFetcher interface {
        GetUser(ctx context.Context, id string) (User, error)
    }

    func NewHandler(fetch userFetcher) *Handler { ... }

- SHOULD define interfaces with one or two methods at the consumer, because the consumer knows the minimal behavior it needs.
- MUST NOT export a large interface from a producer package, because the producer cannot predict consumer needs and large interfaces force unnecessary implementations.
- MUST NOT use any where a concrete type or small interface suffices, because any erases compile-time checks.
- SHOULD model small interfaces on io.Reader and io.Writer, because those demonstrate minimal focused contracts.

## Concurrency

Shared state requires synchronization. Goroutines require an owner and a shutdown path.

BAD:

    var count int
    for _, id := range ids {
        go func() { count++ }() // data race
    }

GOOD:

    var wg sync.WaitGroup
    var mu sync.Mutex
    count := 0
    for _, id := range ids {
        wg.Add(1)
        go func(id string) {
            defer wg.Done()
            u, err := GetUser(ctx, id)
            if err == nil {
                mu.Lock()
                count++
                mu.Unlock()
            }
        }(id)
    }
    wg.Wait()

- MUST synchronize shared state with sync.Mutex, sync.Map, or channels, because unsynchronized access causes data races.
- SHOULD use golang.org/x/sync/errgroup for concurrent work that can fail, because errgroup propagates the first error and cancels siblings.
- MUST NOT leak goroutines, because each leaked goroutine retains memory and prevents clean shutdown; every go statement requires a clear owner and termination via ctx.Done or WaitGroup.
- SHOULD replace cached entries wholesale rather than mutating shared structs, because immutable values never go stale and avoid races.

## Defer and Cleanup

defer runs close to acquisition. The pairing survives early returns.

BAD:

    f, _ := os.Open(path)

GOOD:

    f, err := os.Open(path)
    if err != nil {
        return fmt.Errorf("open %s: %w", path, err)
    }
    defer f.Close()

- MUST check the error from the open before deferring Close, because defer on a nil file panics and masks the open error.
- SHOULD handle Close errors where close can fail and the result matters, because data loss hides in an unchecked close.

## Naming and Zero Values

Names use MixedCaps for exported identifiers and mixedCaps for unexported ones. Short names suit small scopes. The zero value is useful when possible.

BAD:

    type UserData struct {
        UserName string
    }
    var m map[string]int
    m["k"] = 1 // panics: nil map

GOOD:

    package user
    type Data struct {
        Name string
    }

    m := make(map[string]int)
    type Counter struct { mu sync.Mutex; n int } // zero value is ready to use

- MUST NOT stutter the package name, because the call site already qualifies the identifier with the package and stutter adds no information.
- SHOULD design zero values that are valid, because a valid zero value allows declaration without a constructor and reduces initialization bugs; bytes.Buffer and sync.Mutex are examples.
- MUST make the choice between var and make explicit for slices, maps, and channels, because nil and empty behave differently and an implicit choice hides panic risk.

## Exports

The set of exported identifiers defines a package's public interface. That interface is a compatibility commitment and determines the package's surface area.

BAD:

    package calc

    // exported helper only used inside the package
    func Normalize(input string) string { ... }

    func Format(input string) string { return Normalize(input) }

GOOD:

    package calc

    func normalize(input string) string { ... }

    func Format(input string) string { return normalize(input) }

- MUST keep the exported surface minimal — only export identifiers that callers outside the package require, because every export is a long-term compatibility constraint.
- MUST use MixedCaps for exported identifiers and mixedCaps for unexported ones, and demote a helper to unexported as soon as it is only used within its own package.
- SHOULD treat adding a new export as a design review — if the identifier serves only an internal step, keep it unexported.
- MUST NOT export implementation details that can be hidden behind a deep module's single exported function; the module should expose one simple function and hide helpers inside.

## Whitespace

Blank lines separate logical blocks. Dense code forces the reader to hold too much state. Whitespace reduces that load.

BAD:

    func Rebuild(ids []string) Result {
        uniq := make([]string, 0, len(ids))
        for _, id := range ids { uniq = append(uniq, id) }
        slices.Sort(uniq)
        uniq = slices.Compact(uniq)
        mu.Lock()
        for _, id := range uniq { delete(cache, id); cache[id] = &entry{} }
        mu.Unlock()
        for _, id := range uniq { if _, err := load(id); err != nil { log.Warn("load error", "err", err) } }
        return Result{IDs: uniq}
    }

GOOD:

    func Rebuild(ids []string) Result {
        uniq := make([]string, 0, len(ids))
        for _, id := range ids {
            uniq = append(uniq, id)
        }

        slices.Sort(uniq)
        uniq = slices.Compact(uniq)

        mu.Lock()
        for _, id := range uniq {
            delete(cache, id)
            cache[id] = &entry{}
        }
        mu.Unlock()

        for _, id := range uniq {
            if _, err := load(id); err != nil {
                log.Warn("load error", "err", err)
            }
        }

        return Result{
            IDs: uniq,
        }
    }

- MUST separate logical blocks inside a function with a blank line, because blocks represent distinct steps and separation reduces cognitive load; examples are gather, process, and return.
- MUST separate top-level declarations with one blank line, because separation marks independent definitions.
- SHOULD keep a function short enough that a blank line suffices; when a function needs sections, extract a method whose name replaces the section comment, because a named function documents intent better than a comment.

## Comments

Comments capture information that code cannot express. Exported types and functions carry interface comments. Implementation comments appear only when the reason is non-obvious.

BAD:

    // loop over ids
    for _, id := range ids {
        uniq = append(uniq, id) // append id
    }

GOOD:

    // Cache stores parsed configs by path. The zero value is ready for use.
    type Cache struct { ... }

    // Get returns the config for path. It returns ErrNotFound when the path
    // has no entry. The returned config is safe for concurrent use.
    func (c *Cache) Get(path string) (*Config, error) { ... }

- MUST write interface comments before implementation, because the interface defines the contract and a concise comment tests whether the abstraction is sound.
- Interface comments MUST describe what the exported identifier does, its parameters and constraints, what it returns, and what can go wrong. The comment MUST NOT describe how the identifier is implemented, because the implementation is hidden detail and the comment would become stale.
- Implementation comments SHOULD appear only when the code cannot express the why, because why is not visible in syntax; examples are pooling rationale or ordering constraints.
- MUST delete comments that restate the code, because restatement adds no information and obscures useful comments; when a name needs a comment to explain it, rename the identifier.

## Project Layout

Imports point in one direction. The core defines its own types. Adapters at the edge translate external types to core types.

BAD:

    import "example.com/app/internal/payments/stripe" // core imports vendor

GOOD:

    package core
    type Payment struct { ID string; Amount int }

    package stripeadapter
    func toCore(s stripe.Charge) core.Payment { return core.Payment{ID: s.ID, Amount: s.Amount} }

- MUST keep internal/ for non-public packages, because internal enforces encapsulation at the compiler level.
- MUST NOT let core import adapters, because dependencies must point one way toward the core and reversal creates cycles and leaks external types.
- SHOULD hide complexity behind a deep module, because the module exposes a simple function and hides pooling and caching inside and reduces API surface; Format(*Document, Options) (string, error) is an example shape, with hidden internals.
- SHOULD run go vet and golangci-lint before considering Go code complete, because static checks catch idiom violations early.

## Testing

Tests are table-driven. Helpers carry t.Helper. Pure logic uses values alone.

BAD:

    func TestAdd(t *testing.T) {
        if Add(2, 3) != 5 {
            t.Fail()
        }
    }

GOOD:

    func mustLoad(t *testing.T, src string) *Config {
        t.Helper()
        cfg, err := ParseConfig([]byte(src))
        if err != nil {
            t.Fatalf("ParseConfig: %v", err)
        }
        return cfg
    }

    func TestAdd(t *testing.T) {
        tests := []struct {
            name string
            a    int
            b    int
            want int
        }{
            {name: "positive", a: 2, b: 3, want: 5},
            {name: "negative", a: -1, b: 1, want: 0},
        }
        for _, tt := range tests {
            t.Run(tt.name, func(t *testing.T) {
                got := Add(tt.a, tt.b)
                if got != tt.want {
                    t.Errorf("Add(%d,%d) = %d, want %d", tt.a, tt.b, got, tt.want)
                }
            })
        }
    }

- MUST use table-driven tests with t.Run per case, because the table makes cases visible and t.Run isolates failures and enables selective runs; each case has a name field that identifies the failing case.
- MUST mark helpers with t.Helper(), because the helper must report failures at the caller line.
- SHOULD check idempotency where the operation claims it, because repeated application must produce the same result.
- SHOULD test pure logic with values alone and test I/O edges with integration helpers that exercise the real dependency, because mocks hide real behavior.
