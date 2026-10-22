---
appliesTo: ["*.go", "*.ts", "*.tsx", "*.js", "*.rs", "*.py", "*.gleam", "*.nix", "*.nu"]
type: noul
---

# No debugging leftovers

Code should not keep scaffolding from while it was written: a print added to
inspect a value, code commented out in case it is needed again, or a marker
with nobody responsible for it.

- **Violates** — a print or log call that dumps a value to trace it, rather than
  report an event the program cares about: `fmt.Println("here", x)`,
  `console.log(data)`, `dbg!(x)`, `print(resp)`, `builtins.trace`.
- **Violates** — commented-out code: lines of code disabled with comment markers
  instead of deleted.
- **Violates** — a `TODO`, `FIXME`, `XXX` or `HACK` that names no owner and
  no issue.
- **Does not violate** — logging that is intended behaviour, with a level and a
  message a reader would want: `log.Warn("cache miss", "key", key)`.
- **Does not violate** — a `TODO(name)` or a `TODO` that links an issue.
- **Does not violate** — code inside a comment that is an example for the
  reader, such as a usage snippet in a doc comment.

Report a violation only when you can point to one of the leftovers above.
