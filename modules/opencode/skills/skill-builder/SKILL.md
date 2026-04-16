---
name: skill-builder
description: >
  SOP for creating opencode skills and agents. Walks through the full authoring
  workflow from requirements gathering through validation. Covers two skill types:
  SOP skills (step-by-step processes with parameters, constraints, and validation
  gates) and reference skills (principle-based guides with bad/good examples).
  Includes frontmatter spec, description writing, progressive disclosure, and
  agent authoring. Use when building a new skill, creating a new agent, or setting
  up skill/agent directories.
---

# Skill & Agent Authoring

## Overview

This SOP guides you through creating a skill or agent for opencode.

**Skill** — a folder containing a `SKILL.md` file, optionally with `scripts/`, `references/`, and `assets/` subdirectories.

**Agent** — a standalone `.md` file with frontmatter.

Most skills SHOULD be SOPs (step-by-step workflows) rather than reference documents. Reference skills are appropriate only for principle-based guidelines where no sequential process exists.

## Parameters

- **purpose** (required): What the skill should do and when it should trigger. Can be rough.
- **skill_name** (required): Kebab-case name for the skill. MUST be provided or confirmed by user.
- **skill_type** (optional): `sop` (default) or `reference`. Determines structure.
- **target_dir** (optional): Where to create the skill. Defaults to best available location.

**Acquisition constraints:**

- MUST ask for all required parameters upfront in a single prompt
- MUST support: direct text, file path, or existing skill to improve
- MUST confirm parameters before proceeding
- If improving an existing skill, MUST read the current skill first and identify specific gaps

## Steps

### 1. Analyze Requirements

Understand what the skill needs to accomplish and when it should trigger.

**Constraints:**

- MUST ask the user about the skill's purpose and trigger conditions before designing
- MUST identify: who triggers it (user intent), what it produces (output), what it needs (inputs)
- MUST determine skill type:
  - **SOP**: sequential process with steps, validation gates, or decision points
  - **Reference**: independent principles or conventions with no inherent order
- SHOULD ask about edge cases, common mistakes, and failure modes
- MUST NOT skip to writing without understanding the full scope

**Decision guidance:**

| Signal | Type |
|--------|------|
| "walk me through..." / "process for..." / "steps to..." | SOP |
| Has sequential phases, each depends on previous | SOP |
| Needs parameters the user provides at runtime | SOP |
| "conventions for..." / "principles of..." / "rules when..." | Reference |
| Independent guidelines, apply in any order | Reference |
| Pure lookup (naming rules, style guide) | Reference |

### 2. Draft Description

Write the frontmatter description. This is the most important part — it determines whether the skill fires.

**Constraints:**

- MUST follow: `[What it does] + [When to use it] + [Trigger keywords]`
- MUST be in third person (injected into system prompts as-is)
- MUST be 1-1024 characters
- MUST NOT use XML angle brackets
- SHOULD include negative triggers when domain overlaps with common tasks
- MUST present to user for review before proceeding

**BAD:**

```
Helps create opencode skills and agents with proper structure.
```

→ Vague. No trigger phrases. Will never fire.

**GOOD:**

```
SOP for creating opencode skills and agents. Walks through the full
authoring workflow from requirements through validation. Covers SOP skills
(step-by-step processes) and reference skills (principle-based guides).
Use when building a new skill, creating an agent, or setting up
skill/agent directories.
```

→ What, when, trigger phrases all present.

### 3. Create Structure

Set up the skill directory and skeleton.

**Constraints:**

- File MUST be named exactly `SKILL.md` (case-sensitive)
- Folder MUST use kebab-case: lowercase, hyphens only
- MUST NOT include README.md in skill folders (SKILL.md is the single entrypoint)
- MUST present planned structure to user before creating files

**SOP skill structure:**

```
my-skill/
├── SKILL.md          # Overview → Parameters → Steps → Examples → Troubleshooting
├── scripts/          # Optional — validation, generation
├── references/       # Optional — specs, long examples
└── assets/           # Optional — templates
```

**SOP body template:**

```markdown
# [Skill Name]

## Overview
[1-3 sentences: what this SOP does and when to use it]

## Parameters
- **param** (required|optional): description

## Steps

### 1. [Step Name]
[What to do and why]

**Constraints:**
- MUST / SHOULD / MAY rules

### 2. [Step Name]
...

## Examples

### Example Input
...

### Example Output
...

## Troubleshooting

### [Problem]
[Fix]
```

**Reference skill structure:**

```
my-conventions/
├── SKILL.md          # Principles with Bad/Good pairs
└── references/       # Optional — lookup tables, long examples
```

**Reference body template:**

```markdown
# [Convention Name]

## [Principle 1]
[Explanation]

BAD:
    [code]

GOOD:
    [code]

## [Principle 2]
...
```

### 4. Write Content

Fill in the body following type-specific rules.

**Constraints (all types):**

- Default assumption: the agent is already competent. Only add context it lacks.
- MUST use RFC 2119 keywords (MUST, SHOULD, MAY) for all constraints
- Negative constraints (MUST NOT, SHOULD NOT) MUST include a reason
- MUST NOT include time-sensitive information (version numbers, release dates)
- Use consistent terminology — pick one term, use it throughout
- Keep SKILL.md under 500 lines — move excess to `references/`
- Reference files over 100 lines SHOULD include a table of contents

**Constraints (SOP type):**

- Each step MUST have a clear objective the agent can execute
- Steps with constraints MUST use a `**Constraints:**` subsection
- MUST include validation gates: points where the agent waits for user confirmation
- MUST sequence steps so each builds on the previous
- MUST NOT include steps that are purely informational with no action
- Each step SHOULD produce visible output (file created, question asked, etc.)
- Parameters MUST declare: required vs optional, default values, acquisition method

**Constraints (Reference type):**

- Each principle MUST have a concrete Bad/Good pair
- Examples MUST use real code, not pseudocode, unless language-agnostic
- Principles SHOULD be ordered by importance or frequency of violation
- MUST NOT list principles without examples

**Degree of freedom:**

Match specificity to fragility:

- **High freedom** (prose): when multiple valid approaches exist
- **Low freedom** (exact commands/scripts): when operations are fragile or destructive
- For critical validations, prefer bundled scripts over prose (code is deterministic)

### 5. Write Examples

Create at least one end-to-end example.

**Constraints:**

- MUST include at least one complete example showing the full workflow
- Examples MUST use realistic complexity, not trivial cases
- MUST show what the agent produces, not just describe it
- SOP examples SHOULD show: trigger → parameter gathering → step execution → final output
- Reference examples SHOULD show: before/after transformation guided by the principles

**BAD example:**

```
Input: Create a skill
Output: Skill created successfully
```

→ Trivial. Teaches nothing about the interaction pattern.

**GOOD example:**

```
Input: I want a skill that walks me through writing Postgres migrations safely

[Agent gathers parameters: name, target_dir]
[Agent drafts description, presents for review]
[Agent creates structure, shows planned files]
[Agent writes Steps with Constraints subsections]
[Agent validates against checklist]
Output: my-skill/SKILL.md created with 4 steps, 2 examples, passes validation
```

→ Shows the full interaction arc.

### 6. Validate

Run the checklist and iterate.

**Constraints:**

- MUST validate against the checklist in the Reference section below
- MUST test trigger accuracy: ask "When would you use the [skill name] skill?"
- MUST verify the skill does NOT trigger on unrelated tasks
- MUST present findings to user with specific issues and suggested fixes
- MUST NOT consider the skill complete until all checklist items pass

## Reference: Frontmatter Spec

```yaml
---
name: my-skill        # required
description: ...      # required
license: MIT          # optional
compatibility: ...    # optional
metadata:             # optional
  author: jane
  version: "1.0"
allowed-tools: Bash Read  # optional, space-delimited
---
```

| Field | Constraints |
|-------|------------|
| `name` | 1-64 chars. Lowercase alphanumeric + hyphens. No leading/trailing/consecutive hyphens. MUST match folder name. |
| `description` | 1-1024 chars. No XML angle brackets. See Step 2. |
| `license` | Short identifier (MIT, Apache-2.0). |
| `compatibility` | 1-500 chars. Environment requirements. |
| `metadata` | Key-value string map. |
| `allowed-tools` | Space-delimited tool names. |

**Security:** `name` MUST NOT contain "claude" or "anthropic" (reserved). MUST NOT use XML angle brackets in any frontmatter value, because frontmatter is injected into XML-structured system prompts and unescaped brackets break parsing.

## Reference: Progressive Disclosure

Skills load in three levels to minimize context cost:

| Level | What loads | When | Budget |
|-------|-----------|------|--------|
| 1. Frontmatter | `name` + `description` | Always | ~100 tokens |
| 2. SKILL.md body | Core instructions | Agent triggers | Under 500 lines |
| 3. Linked files | references/, scripts/, assets/ | Agent reads explicitly | No cost until accessed |

- Move material over 500 lines to `references/`
- Keep references one level deep — agents may skip deeply nested trees
- Reference files over 100 lines SHOULD include a table of contents

## Reference: Agent Authoring

Agents are standalone `.md` files. Filename determines agent name.

**Location:**

- Global: `~/dotfiles/modules/opencode/agents/<name>.md`
- Project: `.opencode/agents/<name>.md`

**Frontmatter:**

```yaml
---
description: Coordinates multi-step tasks by delegating to specialized subagents.
mode: primary|subagent
permission:
  edit: allow|deny|ask
  bash:
    "*": ask
    "git *": allow
  skill:
    "*": allow
  task:
    "*": allow
---
```

| Field | Required | Notes |
|-------|----------|-------|
| `description` | Yes | Same rules as skill descriptions (Step 2). |
| `mode` | No | `primary` or `subagent`. |
| `permission` | No | Pattern-matched, most specific wins. |

**Body:** role, protocol, constraints. Keep under 100 lines.

**BAD:**

```markdown
You are a helpful assistant that does code review.
```

→ No protocol, no constraints.

**GOOD:**

```markdown
You are the **Code Reviewer**. You review PRs for correctness and style.

## Protocol

1. Read the full diff
2. Check against project conventions (read 3 nearby files)
3. Report issues with file:line references

## Constraints

- MUST NOT suggest style changes that contradict existing patterns
- MUST NOT approve without reading every changed file
```

## Reference: Validation Checklist

### Skills

- [ ] File named `SKILL.md` (case-sensitive)
- [ ] Folder uses kebab-case
- [ ] Frontmatter has `name` and `description`
- [ ] `name` matches folder name
- [ ] `name` does not contain "claude" or "anthropic"
- [ ] Description: 1-1024 chars, third person, what + when + keywords
- [ ] No XML angle brackets in frontmatter
- [ ] No README.md in skill folder
- [ ] Body under 500 lines
- [ ] All constraints use RFC 2119
- [ ] Negative constraints include reasons
- [ ] **SOP**: has Parameters, Steps with Constraints, Examples
- [ ] **SOP**: steps have validation gates
- [ ] **Reference**: each principle has Bad/Good pair
- [ ] At least one complete example

### Agents

- [ ] File uses `.md` extension
- [ ] Frontmatter has `description`
- [ ] Description: 1-1024 chars
- [ ] No XML angle brackets
- [ ] Body under 100 lines
- [ ] Has Protocol and Constraints sections
- [ ] `mode` is `primary` or `subagent` (if specified)

## Troubleshooting

### Skill doesn't trigger

- Missing trigger phrases — add the exact words users would say
- Competing skill with overlapping description — narrow yours
- XML brackets in frontmatter breaking parsing — remove them
- Debug: ask the agent "When would you use the [skill name] skill?"

### Skill triggers too broadly

- Add negative triggers: "Do NOT use for X — use Y instead"
- Narrow the description to specific scope
- Remove generic keywords matching unrelated tasks

### Agent produces wrong output

- Add concrete input/output examples
- Tighten constraints with RFC 2119 language
- Check if wrong skill type (SOP vs reference)

### Skill over 500 lines

- Move lookup tables, API specs, long examples to `references/`
- Remove content restating what competent agents already know
- Consolidate overlapping sections

### Examples feel trivial

- Use realistic complexity, not "hello world"
- Show edge cases, not just happy paths
- Include the interaction pattern, not just input/output blobs
