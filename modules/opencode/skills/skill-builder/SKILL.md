---
name: skill-builder
description: Load when creating new opencode agents or skills. Provides naming conventions, structure requirements, frontmatter formats, and validation checklist.
---

## Naming Conventions

### Skills
- 1-64 characters
- Lowercase alphanumeric with single hyphens only
- NO leading or trailing hyphens
- NO consecutive hyphens
- MUST match the folder name

### Agents
- Filename determines agent name (e.g., `orchestrator.md` creates `orchestrator` agent)
- MUST use `.md` extension

## Description Requirements

MUST include:
1. WHAT the skill/agent does
2. WHEN to use it
3. Trigger phrases users would say

MUST NOT:
- Exceed 1024 characters
- Contain XML angle brackets (`<` or `>`) in frontmatter

## Directory Structure

```
~/.config/opencode/
├── skills/
│   └── <skill-name>/
│       └── SKILL.md
├── agents/
│   └── <agent-name>.md
```

OR in project root:
```
.opencode/
├── skills/<skill-name>/SKILL.md
└── agents/<agent-name>.md
```

## Frontmatter

### Agents
```yaml
---
description: ...
mode: primary|subagent
temperature: 0.1
permission:
  edit: allow|deny|ask
  bash:
    "*": ask|allow|deny
    "git *": allow
  skill:
    "*": allow|deny|ask
  task:
    "*": allow|deny|ask
---
```

### Skills
```yaml
---
name: skill-name
description: ...
---
```

## Content Guidelines

- Agents: keep under 100 lines
- Skills: keep under 500 lines
- Use RFC 2119 keywords (MUST, SHOULD, MAY) for all constraints
- NEVER use sycophantic language ("Good call", "Great question", etc.)
- Be direct and concise

## Trigger Phrases

Example triggers for a skill:
- "Create a new agent for..."
- "I need a skill that..."
- "How do I add a new..."

Example triggers for an agent:
- "Use the orchestrator agent"
- "Delegate to subagent"

## Validation Checklist

Before committing:
- [ ] SKILL.md exists (case-sensitive)
- [ ] Frontmatter has required fields
  - Skills: `name` + `description`
  - Agents: `description`
- [ ] Name matches folder/filename exactly
- [ ] Description under 1024 characters
- [ ] No XML brackets in frontmatter
- [ ] All constraints use RFC 2119 language (MUST/SHOULD/MAY)

## Creating a Skill

1. Create directory: `mkdir -p ~/.config/opencode/skills/<name>`
2. Create SKILL.md with frontmatter
3. Add content following guidelines
4. Validate against checklist

## Creating an Agent

1. Create file: `~/.config/opencode/agents/<name>.md`
2. Add frontmatter with description, mode, permissions
3. Add agent content
4. Validate against checklist
