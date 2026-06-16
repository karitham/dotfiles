# Ghostty

## Source

- Repo: `ghostty-org/website` (branch: `main`)
- Book path: `docs/`
- URL pattern: `https://raw.githubusercontent.com/ghostty-org/website/main/docs/{path}.mdx`
- Contents API: `https://api.github.com/repos/ghostty-org/website/contents/docs`
- Rendered: `https://ghostty.org/docs`

## Notes

- Files are `.mdx` (markdown + JSX). The agent can consume them as markdown; inline JSX is rare in reference pages and safe to skip.
- Subdirs: `config/`, `features/`, `help/`, `install/`, `linux/`, `vt/`.

## Common chapters

| File | Covers |
|---|---|
| `index.mdx` | Top-level landing page |
| `install/binary.mdx` | Installing from prebuilt binary |
| `install/build.mdx` | Building from source (zig build) |
| `install/pre.mdx` | Pre-release builds |
| `install/package.mdx` | Distribution packages (brew, nix, etc.) |
| `config/index.mdx` | Config file location and format |
| `config/reference.mdx` | Full config-key reference (very large) |
| `features/shell-integration.mdx` | Shell integration protocol |
| `features/ssh.mdx` | SSH integration |
| `features/theme.mdx` | Built-in themes and custom themes |
| `features/applescript.mdx` | macOS AppleScript control |
| `features/index.mdx` | Feature overview |
| `help/index.mdx` | Troubleshooting landing page |
| `help/gtk-single-instance.mdx` | GTK single-instance bug workaround |
| `help/gtk-opengl-context.mdx` | OpenGL context issues |
| `help/macos-tiling-wms.mdx` | Running alongside yabai, Aerospace, etc. |
| `help/macos-login-shells.mdx` | macOS login shell PATH issues |
| `help/terminfo.mdx` | Terminfo definitions for Ghostty |
| `help/synchronized-output.mdx` | Synchronized output mode (iTerm2 protocol) |
| `linux/index.mdx` | Linux-specific notes |
| `linux/systemd.mdx` | systemd user service for Ghostty |
| `vt/index.mdx` | Virtual terminal overview |
| `vt/reference.mdx` | VT escape sequence reference |
| `vt/external.mdx` | External VT references |
