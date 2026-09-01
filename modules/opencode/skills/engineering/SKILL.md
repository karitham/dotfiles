---
name: engineering
description: Coordinates engineering work across design, implementation, debugging, testing, documentation, and review. Classifies scope, selects specialist skills, and verifies that structure, implementation, and evidence fit the task. Use when planning, changing, debugging, or reviewing software, configuration, or engineering workflows. Do NOT use for standalone prose editing or knowledge queries.
---

# Engineering

## Overview

The engineering skill coordinates work across the engineering skills. It classifies the task, identifies the affected boundaries, selects the smallest useful set of specialist skills, and checks the result before reporting completion.

The agent uses this workflow for software, configuration, automation, and other engineering tasks. The agent loads language-specific guidance only when the task requires it. The workflow does not replace a specialist skill. It decides when that skill applies and keeps the work in scope.

## Parameters

- **task_scope** (required): One sentence that states the requested outcome.
- **files_changed** (optional): Files already changed by the caller. Infer the list from the working copy when empty.
- **observed_failure** (optional): The failure, unexpected behavior, or test output that triggered the task.

## Steps

### 1. Gate scope

Read the relevant files, local instructions, and current diff before planning a change.

**Constraints:**

- MUST classify the task as `trivial` or `non-trivial`.
- MUST classify a typo, comment change, formatting change, or isolated rename as `trivial` unless it changes behavior.
- MUST classify behavior changes, API changes, boundary changes, multi-file changes, and investigations as `non-trivial`.
- MUST record the decision in one line, such as `trivial: gated` or `non-trivial: full scan`.
- MUST NOT expand a trivial task into an unrelated refactor, because the refactor would obscure the requested change.
- MUST record structural debt with an owner and expiry when the ideal fix sits outside the task scope.

### 2. Map the task

Describe the task in terms of its requested outcome, affected code or documents, external boundaries, side effects, and available evidence.

**Constraints:**

- MUST identify the input, output, and observable acceptance criteria.
- MUST identify public interfaces, data stores, network calls, process boundaries, and generated files that the change may affect.
- MUST separate observed facts from hypotheses when `observed_failure` is present.
- MUST ask a targeted question when a missing requirement blocks a safe decision. MUST proceed with the known scope when the missing detail does not block progress.

### 3. Select specialist skills

Load the specialist that owns the next decision. Load more than one when the task crosses concerns.

| Task signal | Load first | Add when relevant |
| --- | --- | --- |
| Software implementation, refactoring, public APIs, module boundaries, data flow, or system structure | `software-design` | A language or domain skill |
| Go language rules | `go` | `upfluence-go` in an Upfluence repository |
| Unexpected behavior, crashes, failing tests, or production errors | `debugging` | `software-design` after the cause is established |
| Test-driven implementation or test design | `code-assist` | The language or domain skill |
| Completed diff or pull request review | `code-review` | `go` or another language skill |
| Technical prose, documentation, comments, or task descriptions | `plain-technical-prose` | A domain skill when the content requires it |
| Skill, agent, or workflow authoring | `skill-builder` | `plain-technical-prose` |
| Jujutsu status, history, commits, or other VCS operations | `vcs` | None |
| Questions answered from the persistent notes | `knowledge-query` | None |
| Current syntax or behavior of a supported external tool | `book-refs` | The relevant implementation skill |

**Constraints:**

- MUST load `software-design` before writing or revising non-trivial code or changing module boundaries, public interfaces, dependency direction, or data flow.
- MUST load language-specific guidance after the structural decision and before polishing language-specific code.
- MUST load `debugging` before changing code in response to an unexplained failure.
- MUST NOT load a specialist only because a filename matches its domain, because the task scope determines the required expertise.

### 4. Design before tactics

Use the selected structural guidance before applying local code or prose rules.

**Constraints:**

- MUST prefer the smallest structure that meets the acceptance criteria.
- MUST keep external I/O at boundaries and keep deterministic logic separate when the task contains both.
- MUST keep each concept owned by one module or context and translate it at boundaries.
- MUST preserve existing conventions unless a requirement justifies a change.
- MUST keep a trivial change local even when nearby structural debt is visible.
- MUST confirm before destructive or irreversible actions, including data deletion, schema changes, force-pushes, and file replacement.

### 5. Implement and inspect

Make the smallest change that satisfies the acceptance criteria. Inspect the affected files and diff after editing.

**Constraints:**

- MUST validate inputs at the earliest boundary that has enough information to reject them.
- MUST keep error handling explicit and preserve useful context.
- MUST add or update tests when behavior changes and the repository has a test convention for the affected code.
- MUST NOT introduce a new abstraction, dependency, or configuration switch without a task-relevant reason, because each addition expands the maintenance surface.
- MUST NOT claim a verification result that the agent did not run or observe, because an unobserved result is not evidence.

### 6. Verify and report

Run the checks that correspond to the changed surface. Report the result, remaining debt, and any unverified assumption.

**Constraints:**

- MUST verify the requested behavior and the relevant local conventions.
- MUST run focused tests, linters, formatters, or builds when the repository provides them and the change affects their scope.
- MUST inspect the final diff for unrelated changes, missing files, accidental generated output, and leaked secrets.
- MUST dispatch the `reviewer` subagent for non-trivial code changes before reporting completion.
- MUST skip the reviewer for documentation-only, formatting-only, generated, and trivial configuration changes.
- MUST record unresolved structural debt with an owner and expiry instead of silently expanding scope.
- MUST NOT report the change as complete until the relevant checks pass or an exception is recorded with an owner and expiry, because failed or missing checks leave the acceptance criteria unsupported.

## Examples

### Example input

Add retry handling to an HTTP client and document the new behavior.

### Example flow

1. Gate the task as `non-trivial: full scan` because it changes runtime behavior and documentation.
2. Map the client boundary, retry policy, caller-visible errors, tests, and documentation files.
3. Load `software-design`, the language skill for the client, and `plain-technical-prose`.
4. Keep retry ownership inside the HTTP client so callers see one simple operation and one error contract.
5. Implement bounded retries with deterministic tests. Update the documentation to describe the behavior and limits.
6. Run the focused tests and lint checks. Inspect the diff. Dispatch `reviewer`. Report the checks and any unverified network behavior.

## Troubleshooting

### The selected skill does not match the decision

Return to Step 2 and identify the affected boundary or failure. Load the skill that owns that decision. Do not force `software-design` to answer an unexplained failure or a language-specific question.

### A trivial task expands into a refactor

Return to Step 1 and record `trivial: gated`. Apply only the requested change. Record structural debt with an owner and expiry.

### A specialist adds rules that conflict with the repository

Read the local instructions and three nearby files. Preserve the repository convention unless the task explicitly changes it. Record the conflict in the report when it remains unresolved.

### Verification is unavailable

State which check could not run and why. Run the narrowest available static or focused check. Do not report the task as fully verified.
