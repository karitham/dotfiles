# Atuin

## Source

- Repo: `atuinsh/atuin` (branch: `main`)
- Book path: `docs/docs/` (mkdocs — note the doubled `docs/`)
- URL pattern: `https://raw.githubusercontent.com/atuinsh/atuin/main/docs/docs/{path}.md`
- Contents API: `https://api.github.com/repos/atuinsh/atuin/contents/docs/docs`
- Rendered: `https://docs.atuin.sh/`

## Notes

- The `docs/docs/` path is doubled: the outer `docs/` is the mkdocs project, the inner `docs/` is the markdown source.
- Subdirs: `configuration/`, `guide/`, `reference/`, `self-hosting/`, `ai/`.

## Common chapters

| File | Covers |
|---|---|
| `index.md` | Landing / overview |
| `faq.md` | Common questions |
| `integrations.md` | Editor and shell integrations |
| `known-issues.md` | Known bugs and workarounds |
| `sync-v2.md` | Sync server v2 protocol |
| `uninstall.md` | Removing Atuin |
| `configuration/config.md` | Full config reference (large) |
| `configuration/key-binding.md` | Default and custom key bindings |
| `configuration/advanced-key-binding.md` | Key binding DSL details |
| `guide/getting-started.md` | First-time setup |
| `guide/installation.md` | Install methods |
| `guide/basic-usage.md` | Search, list, stats basics |
| `guide/advanced-usage.md` | Filters, prefix, interactive search |
| `guide/shell-integration.md` | Ctrl-R, up-arrow, init scripts |
| `guide/sync.md` | Self-hosted and Atuin Cloud sync |
| `guide/import.md` | Importing from bash/zsh/fish/zsh history |
| `guide/theming.md` | UI theming |
| `guide/agent-hooks.md` | Pre-command and other hooks |
| `guide/dotfiles.md` | Recommended dotfiles integration |
| `guide/delete-history.md` | Deleting entries |
| `reference/search.md` | Search query syntax |
| `reference/sync.md` | Sync command reference |
| `reference/stats.md` | Stats command |
| `reference/list.md` | Listing history |
| `reference/info.md` | Inspecting entries |
| `reference/daemon.md` | Background daemon |
| `reference/doctor.md` | Diagnostics command |
| `reference/pty-proxy.md` | PTY capture for context |
| `self-hosting/server-setup.md` | Running the sync server |
| `self-hosting/kubernetes.md` | K8s deployment manifests |
| `self-hosting/docker.md` | Docker compose for the server |
| `self-hosting/systemd.md` | systemd unit for the server |
| `self-hosting/usage.md` | Client config for self-hosted |
