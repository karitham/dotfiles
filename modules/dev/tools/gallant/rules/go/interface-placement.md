---
appliesTo: "*.go"
type: noul
---

# Interfaces belong to the consumer

Define an interface in the package that consumes it, not in the package that
implements it.

An interface describes what a _caller_ needs, so it should be written from the
caller's point of view. When the implementing package declares it, the contract
is derived from the implementer's own shape rather than from a real use, every
consumer is dragged into depending on the whole thing, and the interface tends
to grow past what anyone actually calls. Defining it at the call site keeps the
contract as small as that use requires and keeps implementers from dictating
coupling.

Judge the file by what it declares, not by what it imports or uses. Start by
looking for interface declarations — a `type Name interface { ... }`. A struct,
a named type over a built-in, or a function is not an interface, and a file that
declares no interface cannot violate this rule no matter what else it contains,
so answer no.

- **Violates** — the file declares an interface and also declares the concrete
  type, or types, that implement it, when nothing else in the file consumes it.
  The interface was written to describe this package's own implementation.
- **Violates** — the file declares an interface whose apparent purpose is to
  wrap a single implementation that lives in the same package.
- **Does not violate** — the file declares an interface with no implementation
  in the same file. That is a consumer stating what it needs from elsewhere.
- **Does not violate** — the file declares a concrete type and no interface.
  Concrete types are the normal thing for a package to define and export.

For example, this file violates it, because the interface exists
only for the implementation beside it:

```go
type Store interface{ Get(id string) (string, error) }

type memoryStore struct{}

func (memoryStore) Get(id string) (string, error) { return "", nil }
```

This file does not, because the interface states what it needs from elsewhere:

```go
type Store interface{ Get(id string) (string, error) }
```

Skip interfaces that back a public, widely-consumed API whose consumers you
cannot see from here, and interfaces that exist only to satisfy an external
contract. These are cases where the file cannot tell you where the consumer is.
