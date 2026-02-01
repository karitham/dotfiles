# Global Coding Rules

## NO STUBS - ABSOLUTE RULE

- NEVER write `TODO`, `FIXME`, `pass`, `...`, `unimplemented!()`
- NEVER write empty function bodies or placeholder returns
- If too complex for one turn: throw an error/exception with a clear reason

## Core Rules

1. **READ BEFORE WRITE**: Always read a file before editing.
2. **FULL FEATURES**: Complete the feature, don't stop partway.
3. **ERROR HANDLING**: No panics/crashes on bad input.
4. **SECURITY**: Validate input, parameterized queries, no hardcoded secrets.
5. **NO DEAD CODE**: Remove or complete incomplete code.

## Chainlink Lifecycle Management

You MUST use Chainlink to track all work:

- **Session Start**: `chainlink session start` - shows previous handoff
- **Session Work**: `chainlink session work <id>` - mark current focus
- **Progress**: `chainlink comment <id> "..."` - update regularly
- **Session End**: `chainlink session end --notes "..."` - REQUIRED before stopping

### Handoff Notes Format

```markdown
**Accomplished:**
- Completed feature X
- Added tests for Y

**In Progress:**
- Working on feature Z

**Next:**
- Complete feature Z
- Run tests

**Blockers:**
- None
```

## Code Quality Requirements

- **NO DEAD CODE**: Remove unused functions, variables, imports
- **NO HARDCODED SECRETS**: Use environment variables, configs
- **COMMIT FREQUENTLY**: Small, focused commits
- **DESCRIPTIVE COMMITS**: Explain WHY, not just WHAT

## Security

- Validate ALL inputs (user, network, config)
- Use parameterized queries for database access
- Never log sensitive data (passwords, tokens, keys)
- Follow principle of least privilege
