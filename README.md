# dotfiles

NixOS flake-based system and user configuration. Managed with [Jujutsu (jj)](https://github.com/martinvonz/jj).

## Hosts

| Host | Type | Arch | Notes |
|------|------|------|-------|
| kiwi | Laptop | x86_64 | Work — Niri, Waybar, YubiKey, Linear/Sentry MCP |
| belaf | Laptop | x86_64 | Personal — Niri, Secure Boot (Lanzaboote) |
| ozen | WSL | x86_64 | Dev environment on Windows |
| reg | Server | x86_64 | Tailscale, SSH, PDS |
| wakuna | Server | aarch64 | ARM — built as SD image |

## Stack

- **System**: NixOS unstable, Lix, flake-parts, easy-hosts
- **User**: home-manager, Catppuccin (macchiato)
- **Desktop**: Niri / Noctalia Shell, Ghostty, Helium browser
- **Dev**: Nushell, Starship, Atuin, Zellij, Helix (custom fork), Jujutsu, Docker, direnv
- **AI**: OpenCode — custom agents, skills, MCP (GitHub, Outline, Linear, Sentry)
- **Secrets**: sops-nix (age)
- **Cache**: Attic → nix-cache.karitham.dev/dotfiles

## Quick Start

```bash
nh os switch                    # rebuild & switch (uses ~/dotfiles)
nixos-rebuild switch --flake .#kiwi  # explicit host
nix build .#wakuna-image        # SD image for wakuna
nix fmt                         # format all files (nixfmt, nufmt, biome)
```

## Structure

```
flake.nix              # Flake entry point
flake-parts.nix        # Flake-parts hub: systems, packages, module exports
modules/
├── core.nix           # my.username option, user groups
├── nix.nix            # Lix config, Attic cache push
├── locale.nix         # Europe/Paris, en_US + fr_FR
├── home/              # home-manager + Catppuccin
├── desktop/           # Niri/Noctalia, Ghostty, audio, apps
├── dev/               # Nushell, Helix, jj, Docker, OpenCode
├── server/            # Tailscale, SSH
├── wsl/               # NixOS-WSL
├── tags/              # work, secureboot
└── opencode/          # AI assistant: agents, skills, plugins, commands
systems/
├── default.nix        # easy-hosts host definitions
├── kiwi/ belaf/ ozen/ reg/ wakuna/
pkgs/                  # Custom package derivations
secrets/               # sops-nix encrypted (age)
```

## Module System

`flake.nix` imports `flake-parts.nix`, which defines the supported systems, custom packages, and exports NixOS/home-manager modules.

Hosts are defined declaratively in `systems/default.nix` via [easy-hosts](https://github.com/tgirlcloud/easy-hosts). Each host has a **class** (`desktop`, `server`, `wsl`) that pulls in the corresponding module group, and optional **tags** (`work`, `secureboot`) that layer in additional config.

`desktop.enable = true` cascades to: wm, terminal, audio, apps, and sub-features.
`dev.enable = true` cascades to: shell, editor, vcs, tools, opencode, Docker.

Most features provide both a NixOS module (`nixos.nix`) and a home-manager module (`home.nix`).

## Secrets

sops-nix with age encryption. Files in `secrets/` are decrypted at build time. Keys and creation rules are in `.sops.yaml`.
