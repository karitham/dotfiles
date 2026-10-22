---
appliesTo: "*.go"
type: noul
---

# Guard early, keep the happy path left

Error and edge cases return first, and the main work stays at the left margin.
An `else` after a branch that returns adds nesting and hides the flow.

- **Violates** — an `else` or `else if` that follows a branch ending in
  `return`, `continue`, `break` or `panic`:

  ```go
  if err != nil {
      return err
  } else {
      use(v)
  }
  ```

- **Violates** — the main work nested inside a success check instead of
  returning on the failure first:

  ```go
  if data, err := os.ReadFile(p); err == nil {
      return parse(data)
  } else {
      return nil, err
  }
  ```

- **Does not violate** — an `if`/`else` where neither branch returns and both
  are real alternatives.
- **Does not violate** — a `switch` with a `default` case.

Report a violation only when you can point to one of the shapes above.
