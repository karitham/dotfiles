---
name: skill-builder
description: Guide for creating opencode skills and agents. Covers skill directory structure, SKILL.md frontmatter format, writing effective descriptions with trigger phrases, progressive disclosure across three loading levels, content patterns (templates, workflows, feedback loops), agent file format with permissions, testing strategies, and a validation checklist. Use when building a new skill, creating a new agent, or setting up skill/agent directories.
---

# Skill & Agent Authoring

You are creating a skill or agent for opencode. A skill is a folder containing a `SKILL.md` file. An agent is a standalone `.md` file. Both use YAML frontmatter + markdown body.

## 1. Skill Structure

```
<skill-name>/
├── SKILL.md          # required — the single entrypoint
├── scripts/          # optional — bundled scripts for validation, generation
├── references/       # optional — detailed docs, specs, examples
└── assets/           # optional — templates, config files
```

- File MUST be named exactly `SKILL.md` (case-sensitive)
- Folder MUST use kebab-case: lowercase, hyphens only, no spaces/capitals/underscores
- MUST NOT include a README.md inside skill folders, because SKILL.md is the single entrypoint and a README creates ambiguity about which file is authoritative
- Skills live at `~/.config/opencode/skills/<name>/` (global) or `.opencode/skills/<name>/` (project-local)

## 2. Frontmatter Reference

```yaml
---
name: my-skill              # required
description: ...            # required
license: MIT                # optional
compatibility: ...          # optional
metadata:                   # optional
  author: jane
  version: "1.0"
allowed-tools: Bash Read    # optional, space-delimited
---
```

| Field | Constraints |
|---|---|
| `name` | 1-64 chars. Lowercase alphanumeric + hyphens. No leading/trailing/consecutive hyphens. MUST match folder name. |
| `description` | 1-1024 chars. No XML angle brackets. See §3. |
| `license` | Short license identifier (e.g., MIT, Apache-2.0). |
| `compatibility` | 1-500 chars. Environment requirements (OS, runtime, tools). |
| `metadata` | Key-value string map. |
| `allowed-tools` | Space-delimited tool names pre-approved for this skill. |

Security constraints:
- MUST NOT use XML angle brackets (`<` `>`) in any frontmatter value, because frontmatter is injected into XML-structured system prompts and unescaped brackets break parsing
- `name` MUST NOT contain "claude" or "anthropic" (reserved)

## 3. Writing Effective Descriptions

The description is the most important part of a skill. It determines whether the agent loads the skill. Descriptions are injected into the system prompt as-is, so they MUST be written in third person.

### Structure

```
[What it does] + [When to use it] + [Key capabilities/keywords]
```

Front-load the primary use case. Include trigger phrases — the words a user would actually say.

### Good Examples

```
Systematic debugging protocol emphasizing empirical investigation over code
reasoning. Covers the observe-hypothesize-experiment-narrow loop, establishing
failure conditions, gathering evidence from logs and git history. Use when
investigating crashes, test failures, unexpected behavior, or any situation
where the system is not doing what it should.
```

```
Guide for writing database migrations in PostgreSQL. Covers safe column
additions, index creation with CONCURRENTLY, data backfills, and rollback
strategies. Use when creating, modifying, or reviewing database migrations.
Keywords: schema change, ALTER TABLE, CREATE INDEX.
```

```
Enforces clean coding conventions for any implementation task. Covers guard
clauses, happy-path alignment, pure functions, error handling. Use when writing
new code, refactoring, fixing bugs, or reviewing code for quality.
```

### Bad Examples

- `"Helps with projects"` — too vague, no trigger conditions, will never fire
- `"A comprehensive tool for managing all aspects of deployment"` — no specifics, no keywords
- `"Use this skill when needed"` — circular, gives the agent nothing to match against

### Preventing Mis-triggers

SHOULD include negative triggers when the skill's domain overlaps with common tasks:

```
Do NOT use for simple one-off SQL queries — only for schema migrations.
```

### Debugging Trigger Issues

Ask the agent: _"When would you use the [skill name] skill?"_ If it cannot answer clearly, the description needs work.

## 4. Progressive Disclosure

Skills load in three levels to minimize context cost:

| Level | What loads | When | Budget |
|---|---|---|---|
| 1. Frontmatter | `name` + `description` | Always (system prompt) | ~100 tokens per skill |
| 2. SKILL.md body | Core instructions | Agent triggers the skill | Keep under 500 lines |
| 3. Linked files | references/, scripts/, assets/ | Agent reads explicitly | No cost until accessed |

Practical guidance:

- SKILL.md SHOULD contain only core instructions the agent needs on every invocation
- Move detailed reference material (API specs, long examples, lookup tables) to `references/` and link to them from SKILL.md
- Keep references one level deep from SKILL.md, because agents may partially read or skip deeply nested file trees
- Reference files over 100 lines SHOULD include a table of contents at the top

## 5. Content Guidelines

Default assumption: the agent is already competent. Only add context it does not already have.

- Be specific and actionable. Not _"handle errors appropriately"_ but _"return errors with context using fmt.Errorf"_
- Use examples (input/output pairs) to show expected behavior
- Use RFC 2119 keywords (MUST, SHOULD, MAY) for all constraints
- Negative constraints (MUST NOT, SHOULD NOT) MUST include a reason explaining why
- Use consistent terminology — pick one term and use it throughout
- MUST NOT include time-sensitive information (version numbers, release dates), because skills are not updated on a schedule

### Degree of Freedom

Match instruction specificity to task fragility:

- **High freedom** (prose instructions): when multiple valid approaches exist. _"SHOULD use guard clauses for early returns."_
- **Low freedom** (exact commands/scripts): when operations are fragile or destructive. _"MUST run `pg_dump` before applying migration."_

For critical validations, prefer bundled scripts over prose instructions, because code is deterministic and prose is interpreted.

## 6. Content Patterns

### Template Pattern

Provide output format templates. Mark required vs. optional sections.

```markdown
## Summary
[required — 1-2 sentences]

## Details
[optional — supporting context]
```

### Workflow Pattern

Sequential steps with validation gates.

```
1. Run linter → MUST pass before proceeding
2. Run tests → fix failures, repeat step 1
3. Generate docs → review output
```

### Feedback Loop Pattern

```
1. Run validator: `./scripts/validate.sh`
2. If errors, fix and go to step 1
3. If clean, proceed
```

### Conditional Workflow

Decision trees for different paths:

```
If new table → use CREATE TABLE template
If adding column → use ALTER TABLE template with NOT NULL + default
If dropping column → require migration plan review first
```

### Examples Pattern

Input/output pairs showing expected behavior:

```
Input:  createUser("jane", "admin")
Output: { id: 1, name: "jane", role: "admin", createdAt: "..." }
```

## 7. Agents

Agents are standalone `.md` files. The filename determines the agent name (`orchestrator.md` → `orchestrator`).

### Location

- Global: `~/.config/opencode/agents/<name>.md`
- Project: `.opencode/agents/<name>.md`

### Frontmatter

```yaml
---
description: Coordinates multi-step tasks by delegating to specialized subagents.
mode: primary|subagent
permission:
  edit: allow|deny|ask
  bash:
    "*": ask
    "git *": allow
    "npm test": allow
  skill:
    "*": allow
  task:
    "*": allow
---
```

| Field | Required | Notes |
|---|---|---|
| `description` | Yes | Same rules as skill descriptions (§3). |
| `mode` | No | `primary` (top-level) or `subagent` (delegated to). |
| `permission` | No | Tool permission overrides. Pattern-matched, most specific wins. |

### Content

Agent body defines role, protocol, and constraints. Keep under 100 lines.

```markdown
You are the **Code Reviewer**. You review pull requests for correctness and style.

## Protocol
1. Read the diff
2. Check against project conventions
3. Report issues with file:line references

## Constraints
- MUST NOT suggest style changes that contradict existing patterns
- MUST NOT approve without reading every changed file
```

## 8. Testing

### Trigger Testing

- Does the skill trigger on direct requests? (_"Create a new skill for..."_)
- Does it trigger on paraphrased requests? (_"I need to set up an agent"_)
- Does it stay silent on unrelated tasks? (_"Fix this CSS bug"_)

### Functional Testing

- Does it produce correct output for typical inputs?
- Does error handling work (missing fields, invalid names)?
- Are edge cases covered (empty descriptions, long names)?

### Iteration

| Problem | Fix |
|---|---|
| Under-triggering | Add more keywords and trigger phrases to description |
| Over-triggering | Be more specific, add negative triggers |
| Wrong output | Add examples, tighten constraints |

Debug with: _"When would you use the [skill name] skill?"_

## 9. Validation Checklist

### Skills

- [ ] File is named `SKILL.md` (case-sensitive)
- [ ] Folder uses kebab-case
- [ ] Frontmatter has `name` and `description`
- [ ] `name` matches folder name exactly
- [ ] `name` does not contain "claude" or "anthropic"
- [ ] Description is 1-1024 characters
- [ ] Description includes what, when, and trigger keywords
- [ ] Description written in third person
- [ ] No XML angle brackets in frontmatter
- [ ] No README.md in skill folder
- [ ] Body under 500 lines
- [ ] All constraints use RFC 2119 language
- [ ] Negative constraints include a reason

### Agents

- [ ] File uses `.md` extension
- [ ] Frontmatter has `description`
- [ ] Description is 1-1024 characters
- [ ] No XML angle brackets in frontmatter
- [ ] Body under 100 lines
- [ ] `mode` is `primary` or `subagent` (if specified)
- [ ] Permission patterns are valid

## 10. Anti-patterns

- **Vague descriptions** — _"Helps with projects"_ tells the agent nothing
- **Missing trigger phrases** — skill exists but never fires
- **Deeply nested references** — agents lose track past one level of nesting
- **Too many options without a default** — _"you could use A, B, or C"_ without guidance on which to pick
- **Time-sensitive content** — version numbers and dates go stale silently
- **Inconsistent terminology** — using "skill", "plugin", and "extension" interchangeably
- **Backslash paths** — use forward slashes; backslashes break on Unix systems
