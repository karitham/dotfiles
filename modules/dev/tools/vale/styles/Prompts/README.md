# Prompts

Vendored from [jdkato/Prompts](https://github.com/jdkato/Prompts) at commit
`0fb3361da35a7b5d6934a9a3b4a6effda4fbba77`, MIT license.

Vale style for instruction files: `AGENTS.md`, `CLAUDE.md`, `SKILL.md`, and
system prompts. The rules report imperative mood, vague verbs, absolutes,
contradictions, length, emphasis, skill frontmatter, triggers, time-sensitive
text, and backslash paths.

`SectionLength.yml` is omitted because it requires Vale 3.21.0 and this
repository pins 3.17.1. Add it when the package moves to 3.21.0 or later.

The agent prompt frontmatter uses folded `description: >` values. The
`Trigger`, `ThirdPerson`, and `Frontmatter` rules read an inline `description:`
line, so `.vale.ini` disables them for `agents/*.md`, `AGENTS.md`, and
`CLAUDE.md`; they remain enabled for `SKILL.md`, whose frontmatter is inline.
