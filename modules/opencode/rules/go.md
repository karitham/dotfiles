### Go Best Practices

Follow [Effective Go](https://go.dev/doc/effective_go) and [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments).

#### Code Style & Structure

- **Existing Style**: The best Go style is the existing style. Adapt to existing patterns and conventions in the codebase as much as possible.
- **Small Interfaces**: Keep interfaces small (often 1-3 methods). "The bigger the interface, the weaker the abstraction."
- **Deep Modules**: Design modules with simple interfaces that hide significant complexity (deep vs. shallow).
- **Align Left**: Keep the "happy path" aligned to the left.
- **Early Returns**: Use guard clauses to handle errors and edge cases early, reducing nesting.
- **Avoid Else**: Avoid `else` blocks; they often indicate complex branching that can be flattened with early returns.
- **No Naked Returns**: Avoid using named return parameters for actual returns.
- **Latest Features**: Leverage modern Go features (generics, `any`, `net/http` routing enhancements, `log/slog`, `t.Context()`).
- **Simple Functions**: Write small, focused functions that do one thing well.
- **Avoid God Objects**: Don't create types that try to do everything. Use composition.
- **Pure Code**: Prefer pure functions where possible.
- **Easy to Mock**: Accept interfaces, return structs. Use dependency injection.

#### Error Handling

Always check and handle errors immediately. Wrap errors with context.

```go
// GOOD: Early returns, aligned left, no else
func readConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read config: %w", err)
	}

	var config Config
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("parse config: %w", err)
	}

	return &config, nil
}

// BAD: Nested, use of else, harder to follow
func readConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err == nil {
		var config Config
		err = json.Unmarshal(data, &config)
		if err == nil {
			return &config, nil
		} else {
			return nil, err
		}
	} else {
		return nil, err
	}
}
```

#### Concurrency & Sync

- **Package sync**: Use `sync.Mutex`, `sync.RWMutex`, `sync.Once`, and `sync.Pool` extensively.
- **sync.WaitGroup**: Use for waiting on multiple goroutines.
- **Channels**: Use for coordination between goroutines.
- **Context**: Always propagate `context.Context`. Use `t.Context()` in tests for automatic cleanup.
- **Atomic**: Use `sync/atomic` for simple counter/state updates.

#### Testing

Use the standard `testing` package effectively.

- **Table-Driven Tests**: Use anonymous structs for test cases with clear `name`, `got`, and `want` fields.
- **t.Context()**: Use `t.Context()` for test-scoped context that cancels when the test finishes.
- **Few Functions, Good Tables**: Prefer one robust test function with a comprehensive table over many small test functions.
- **Helper Functions**: Use `t.Helper()` in functions that assist in testing to keep stack traces clean.

```go
func TestSum(t *testing.T) {
	tests := []struct {
		name string
		args []int
		want int
	}{
		{"empty", []int{}, 0},
		{"single", []int{1}, 1},
		{"multiple", []int{1, 2, 3}, 6},
		{"negative", []int{1, -1}, 0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := Sum(tt.args); got != tt.want {
				t.Errorf("Sum() = %v, want %v", got, tt.want)
			}
		})
	}
}
```
