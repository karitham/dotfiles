---
appliesTo: "*.go"
type: noul
---

# Encode invariants in types

When a value has a rule about what it may be, give it a type that can only hold
legal values instead of a built-in type whose rule is re-checked at each use.

A bare `string` or `int` says nothing about its domain, so the rule about it
lives at every place that uses it. A dedicated type moves the rule to one place
— construction — and puts it in the signatures, so the rest of the program can
treat the value as already valid.

These are not violations; do not report them:

- **Does not violate** — a named type over constants. `type Status string` with
  `Status` constants is the desired shape even when the constants are compared
  or `switch`ed: the set has a name and a home.
- **Does not violate** — a struct that groups fields for configuration or
  transport (a config, DTO, request, response, or record). Fields of a built-in
  type are normal; grouping them is not a domain rule.
- **Does not violate** — a check written once, or one the compiler or standard
  library already enforces.

Report a violation only when a domain rule is real and the file re-checks it by
hand at the use sites instead of proving it once when the value is built. There
is a violation only if the file compares a value to literal values of a
built-in type, or repeats the same check, rather than using a named type. If no
such comparison or repeated check is present, answer no; structs, maps,
and functions around named types do not change that.

- **Violates** — a value that must be one of a fixed set (a status, a kind, a
  mode) is held in a built-in type and the set is written out as comparisons at
  the call sites, with no named type to hold it:

  ```go
  func activate(s string) bool { return s == "active" }
  func ban(s string) bool      { return s == "banned" }
  ```

- **Violates** — two parameters, fields, or values share a built-in type but
  must not be interchanged, such as two kinds of id or a sender and a receiver,
  because a caller can swap them and the code still compiles. They need not be
  misused here; the hazard is that nothing stops a caller:

  ```go
  func link(userID, orderID string) // link(a.orderID, a.userID) compiles
  ```

- **Violates** — the same shape or range check for one value is written out at
  two or more sites instead of being done once when the value is built.

This violates the rule, because the set of statuses has no home:

```go
func activate(s string) bool { return s == "active" }
func ban(s string) bool      { return s == "banned" }
```

This does not, because the set has a named type even though it is compared:

```go
type Status string

const (
	Active Status = "active"
	Banned Status = "banned"
)

func activate(s Status) bool { return s == Active }
```

The test is whether a real rule is re-checked at more than one use, or whether
two interchangeable values can actually be confused. A field that merely has a
built-in type does not violate the rule, and a value with no domain rule at all
— an ordinary config, request, or record field — cannot violate it.
