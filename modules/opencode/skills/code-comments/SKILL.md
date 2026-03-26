---
name: code-comments
description: Guide writing high-quality code comments following Ousterhout's principles. Use when writing, reviewing, or improving comments in code. Triggers: "add comments", "how should I comment", "comment this code", "review comments"
---

## What comments are for

Comments exist to capture information that cannot be expressed in code. If a comment only restates what the code already says, it MUST be deleted because it adds noise without value.

## What to comment

Comments MUST describe things that are not obvious from the code:

- Why a decision was made, not what the code does
- Units, valid ranges, and data formats
- Preconditions and postconditions
- Invariants and non-obvious side effects
- Edge cases and their handling rationale

Interface comments (on classes, functions, and modules) MUST describe the abstraction — what it does and how to use it — NOT how it is implemented.

Implementation comments SHOULD only appear when the code itself cannot express the intent clearly. If an implementation comment is needed to explain what the code does, the code SHOULD be simplified instead.

## Comment-driven development

Comments MUST be written before the implementation because writing the interface comment first forces clear thinking about the abstraction before committing to code.

If a clean, concise comment cannot be written for a function or module, the design is likely wrong. Treat the difficulty of commenting as a design smell.

Uncommented public interfaces MUST be treated as incomplete, not finished.

## Constraints

- MUST NOT write comments that repeat the code
- MUST NOT defer comments until after implementation because they become vague and low-value
- MUST describe the abstraction at the interface level, not the implementation details
- SHOULD use comments to capture design rationale that would otherwise be lost
