# flake-parts

## Source

- Repo: `hercules-ci/flake.parts-website` (branch: `main`)
- Book path: `site/src/` (mdBook)
- URL pattern: `https://raw.githubusercontent.com/hercules-ci/flake.parts-website/main/site/src/{file}.md`
- Contents API: `https://api.github.com/repos/hercules-ci/flake.parts-website/contents/site/src`
- Rendered: `https://flake.parts/>

## Common chapters

| File | Covers |
|---|---|
| `getting-started.md` | Migration from vanilla flakes to flake-parts |
| `cheat-sheet.md` | Concise reference card |
| `intro-continued.md` | Module system introduction (continuation) |
| `module-arguments.md` | Defining and using module options (large) |
| `system.md` | The `perSystem` and system-level patterns |
| `overlays.md` | Defining and using overlays inside a flake-parts module |
| `define-module-in-separate-file.md` | Splitting modules into their own files |
| `define-custom-flake-attribute.md` | Adding new top-level flake attributes |
| `dogfood-a-reusable-module.md` | Publishing and consuming your own module |
| `best-practices-for-module-writing.md` | Conventions and pitfalls |
| `debug.md` | `nix flake show` and friends for debugging |
| `generate-documentation.md` | Generating options docs from modules |
