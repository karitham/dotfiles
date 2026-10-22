---
appliesTo: ["*.go", "*.ts", "*.tsx", "*.rs", "*.py", "*.gleam"]
type: noul
---

# No role-named types that hold one behaviour

A type named for a role — `Manager`, `Service`, `Handler`, `Helper`,
`Validator`, `Processor`, `Util` — that exists to hold a single behaviour is
a function in disguise. The type adds a concept, a constructor and a receiver,
and hides nothing. A validator in particular returns an error and leaves the
invalid value usable, where a constructor could return a type that cannot be
invalid.

- **Violates** — a role-named type with one meaningful method and no state, or
  only state that the one method uses:

  ```go
  type EmailValidator struct{}

  func (EmailValidator) Validate(s string) error { ... }
  ```

- **Does not violate** — a type with a role name that owns real state or a
  lifecycle across several operations, such as an HTTP server with routes and
  shutdown.
- **Does not violate** — a type whose name is a domain noun, such as `Order` or
  `Invoice`, whatever its methods are.
- **Does not violate** — a type that implements an interface required by a
  framework or library, such as `http.Handler`.

Report a violation only for such a type in the file. A file
with no role-named type does not violate this rule.
