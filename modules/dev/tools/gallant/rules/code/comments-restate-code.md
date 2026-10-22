---
appliesTo: ["*.go", "*.ts", "*.tsx", "*.js", "*.rs", "*.py", "*.gleam", "*.nix", "*.nu"]
type: noul
---

# Comments state what the code cannot

A comment should give the reader something the code cannot: an invariant, a
constraint, the reason for a choice, or a non-obvious consequence. A comment
that only repeats what the next line plainly does adds nothing, and it drifts
out of sync when the code changes.

- **Violates** — a comment that restates the code it sits on or above:

  ```go
  // increment the counter
  count++

  // return the user
  return user, nil

  // loop over ids
  for _, id := range ids {
  ```

- **Violates** — a doc comment that only repeats the identifier's name, such as
  `// GetUser gets the user.`
- **Does not violate** — a comment that explains why, states an invariant or a
  constraint, or warns about a consequence:

  ```go
  // The server answers one request at a time, so requests are serialised.
  mu.Lock()
  ```

- **Does not violate** — a doc comment that describes parameters, return values,
  or failure modes beyond the name.
- **Does not violate** — tooling directives such as `//go:generate`,
  `//nolint`, `# shellcheck`, or `// @ts-expect-error`.

Report a violation only when you can point to a comment that repeats its code.
A file with no comments does not violate this rule.
