---
name: quality-code
description: Standards for writing and modifying functions. Use when implementing behavior inside existing structure. See software-architecture when the change alters boundaries, interfaces, or data flow. Do not use for diagnosis without implementation.
---

# Quality code

Each function reads as a short list of steps from top to bottom.

- One concern per function. If the name needs "and", or the body mixes policy with mechanics, split it. One level of abstraction per function.
- Pure by default. Take values, return values. Lift I/O, clocks, randomness, and process state to the caller.
- No anemic models. When a function enforces a domain rule on a type it does not own, move the rule onto the type or into its module. Don't add a new service method that checks fields a type already exposes. See software-architecture.
- Guard early. Return on errors and edge cases first; no `else` after a return. Happy path stays left.
- No cleverness. Straight-line code over dense one-liners.
- Small contracts. Zero to two arguments; beyond that, an options object or a smaller operation. Few locals, narrow scopes. Never mutate caller-owned data.
- Fail explicitly. Return failures in the signature; preserve cause and context; never swallow.
- Names carry the design. Name what, not how; include units (`timeoutMs`); booleans read as questions; disclose side effects in the name.
- Comments state what code cannot: invariants, constraints, reasons. Delete commented-out code. Run `vale` on modified files to check comments for hedges, marketing terms, non-ASCII punctuation, and signposting.
- Match the surrounding code's conventions.
