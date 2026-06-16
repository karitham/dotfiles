# OpenCode

## Source

- Repo: `sst/opencode` (branch: `dev`)
- Book path: `packages/web/src/content/docs/`
- URL pattern: `https://raw.githubusercontent.com/sst/opencode/dev/packages/web/src/content/docs/{file}.mdx`
- Contents API: `https://api.github.com/repos/sst/opencode/contents/packages/web/src/content/docs`
- Rendered: `https://opencode.ai/docs`

## Notes

- Default branch is `dev`, not `main`. Hardcode `dev` in the URL.
- Files are `.mdx`. Consume as markdown; JSX is rare in reference pages.
- Locale subdirs (`ar/`, `de/`, `fr/`, `ja/`, `zh-cn/`, etc.) exist — ignore unless the user asks for a translation.

## Common chapters

| File | Covers |
|---|---|
| `index.mdx` | Top-level landing |
| `cli.mdx` | Full CLI reference (flags, env vars, subcommands) |
| `agents.mdx` | Built-in agents, agent configuration, custom agents |
| `config.mdx` | `opencode.jsonc` schema and examples |
| `providers.mdx` | Provider configuration for every supported model (very large) |
| `server.mdx` | `opencode serve` for remote usage |
| `sdk.mdx` | SDK for embedding opencode in other tools |
| `lsp.mdx` | LSP server configuration and built-in servers |
| `mcp-servers.mdx` | MCP server configuration |
| `plugins.mdx` | Plugin authoring and reference |
| `themes.mdx` | Theme system, custom themes |
| `keybinds.mdx` | Keybinding configuration |
| `permissions.mdx` | Permission system (allow/deny/ask) |
| `tools.mdx` | Built-in tools (read, write, edit, bash, etc.) |
| `commands.mdx` | Custom slash-commands |
| `skills.mdx` | Skill authoring and loading |
| `custom-tools.mdx` | Defining custom tools |
| `formatters.mdx` | Formatter configuration |
| `models.mdx` | Model selection and overrides |
| `rules.mdx` | Custom rules and project instructions |
| `github.mdx` | GitHub Actions / automation usage |
| `gitlab.mdx` | GitLab CI integration |
| `go.mdx` | Go-specific guidance (LSP, formatters) |
| `acp.mdx` | Agent Client Protocol |
| `troubleshooting.mdx` | Common issues and fixes |
| `tui.mdx` | Terminal UI reference |
| `web.mdx` | Web UI reference |
| `zen.mdx` | Zen mode / plan-then-execute |
| `enterprise.mdx` | Enterprise SSO / SCIM setup |
| `ide.mdx` | IDE integrations (VS Code, Zed, etc.) |
| `network.mdx` | Network / proxy configuration |
| `policies.mdx` | Organizational policies |
| `references.mdx` | Config reference appendix |
| `share.mdx` | Sharing sessions |
| `windows-wsl.mdx` | Windows + WSL notes |
| `ecosystem.mdx` | Community projects, plugins, themes |
