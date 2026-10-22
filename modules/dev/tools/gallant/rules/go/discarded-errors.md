---
appliesTo: "*.go"
type: noul
---

# Errors are handled, not discarded

A returned error is the only signal that something failed. Discarding it hides
the failure.

- **Violates** — an error assigned to `_` with no comment on that line or the
  line above that says why it is safe to ignore:

  ```go
  data, _ := os.ReadFile(path)
  ```

- **Violates** — a call that returns an error used as a statement, so the error
  is dropped: `json.NewDecoder(r.Body).Decode(&req)`.
- **Violates** — `log.Fatal`, `os.Exit` or `panic` used to handle an error
  from bad input, outside `main` or test code.
- **Does not violate** — `_ = x` or `_, _ =` with a comment giving the reason.
- **Does not violate** — `defer f.Close()` on a file opened for reading, and
  writes to `fmt.Fprint*` on a terminal or `strings.Builder`, whose errors
  are conventionally ignored.
- **Does not violate** — test files that check errors with `t.Fatal`.

Report a violation only when you can point to a discarded error.
