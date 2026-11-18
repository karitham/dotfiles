# proptest-praxis

Vendored from inanna-malick/agent-skills
<https://github.com/inanna-malick/agent-skills>, the skill that
accompanies "Property Testing with Agent Swarms"
<https://recursion.wtf/posts/agents-and-property-tests/>. SKILL.md
stays byte-identical to upstream, so re-vendoring is a plain diff; the
MIT license is in LICENSE. Upstream's agents/openai.yaml is Codex
metadata and is not vendored.

To re-vendor after an upstream change:

    curl -o modules/agents/skills/proptest-praxis/SKILL.md \
      https://raw.githubusercontent.com/inanna-malick/agent-skills/main/skills/proptest-praxis/SKILL.md

Use: give a planning agent this skill plus the parts of a repository
that worry you. The agent builds reference models, generators, and
invariants on a discovery branch, then turns each confirmed bug into a
standalone regression test and fix.
