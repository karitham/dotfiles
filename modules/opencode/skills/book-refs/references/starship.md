# Starship

## Source

- Repo: `starship/starship` (branch: `main`)
- Book path: `docs/` (Vitepress)
- URL pattern: `https://raw.githubusercontent.com/starship/starship/main/docs/{section}/README.md`
- Contents API: `https://api.github.com/repos/starship/starship/contents/docs`
- Rendered: `https://starship.rs/>

## Notes

- Vitepress convention: each section's main page is `README.md`. The agent fetches the section's `README.md`, not a file with the section's name.
- `config/README.md` is the full config reference and is large (~300KB). Fetch in full only when the user needs the whole schema; otherwise the section README in `guide/` covers the conceptual material.
- Locale subdirs (`de-DE/`, `fr-FR/`, `ja-JP/`, etc.) exist — ignore unless the user asks for a translation.

## Common chapters

| File | Covers |
|---|---|
| `guide/README.md` | Conceptual guide (modules, order, format strings) |
| `config/README.md` | Full config reference — every module, every option (large) |
| `faq/README.md` | Common questions and gotchas |
| `installing/README.md` | Install methods |
| `advanced-config/README.md` | Custom commands, conditional logic, transient prompt |
| `migrating-to-0.45.0/README.md` | Migration notes from pre-0.45 configs |
| `presets/README.md` | Curated preset overview |
| `presets/{name}.md` | Individual preset pages (bracketed-segments, gruvbox-rainbow, nerd-font, etc.) |
