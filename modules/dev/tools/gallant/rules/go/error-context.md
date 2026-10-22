---
appliesTo: "*.go"
type: noul
---

# Errors carry context

When a function returns an error from a call into another package, it wraps
the error with what it was doing, so the caller can tell which operation
failed: `fmt.Errorf("load config %s: %w", path, err)`.

- **Violates** — an error from a call into another package, such as `os`,
  `json` or `yaml`, returned bare as `return err` or `return nil, err`.
  One such return is enough:

  ```go
  f, err := os.Open(path)
  if err != nil {
      return err
  }
  cfg, err := parse(f)
  if err != nil {
      return err
  }
  ```

- **Violates** — wrapping with `%v` or `%s` instead of `%w`, which breaks
  `errors.Is` and `errors.As` for the caller.
- **Violates** — comparing errors with `==` or by their message string instead
  of `errors.Is` or `errors.As`.
- **Does not violate** — returning an error bare from a call to a function in
  the same package that already adds context.
- **Does not violate** — returning a sentinel or typed error that the function
  creates itself.

Report a violation only when you can point to one of the shapes above.
