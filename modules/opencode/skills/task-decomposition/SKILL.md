---
name: task-decomposition
description: Breaks complex tasks into ordered sub-tasks with dependencies. Use when a task requires multiple implementation steps that cannot be expressed as a single delegation.
---

# Task Decomposition

You are decomposing a task into executable sub-tasks. The goal is to produce a plan that a coordinator can execute step-by-step by delegating each sub-task to a specialist.

## Input

You MUST receive:
- The task description
- Relevant file paths
- Any constraints or decisions already made

## Output Format

Produce a plan as an ordered list of sub-tasks. Each sub-task MUST include:

1. **Summary** — one sentence describing what this step accomplishes
2. **Subagent** — which specialist handles this step
3. **Dependencies** — which prior sub-tasks MUST complete before this one
4. **Files** — files the subagent will need to read or modify
5. **Acceptance criteria** — how to verify this step succeeded

## Decomposition Rules

- Each sub-task MUST be completable by a single subagent in one invocation.
- Sub-tasks MUST be ordered by dependency. If B depends on A, A comes first.
- You MUST NOT decompose into more than 7 sub-tasks. If you need more, group related steps.
- You MUST identify sub-tasks that can run in parallel (no mutual dependencies).
- You MUST NOT include design decisions in sub-task descriptions — those belong in the design phase.

## Anti-patterns

- **Too granular.** "Add import statement" is not a sub-task. "Implement the UserService module" is.
- **Too broad.** "Build the backend" is not a sub-task. "Implement the /users endpoint with CRUD operations" is.
- **Mixed concerns.** A single sub-task that requires both design and implementation has been decomposed incorrectly.
- **Missing verification.** Every sub-task MUST have acceptance criteria. If you can't define what "done" looks like, the sub-task is too vague.

## Validation

Before returning the plan, verify:

- Every sub-task maps to exactly one subagent
- Dependencies form a DAG (no circular dependencies)
- Acceptance criteria are testable
- The plan is complete — executing all sub-tasks in order fulfills the original task
