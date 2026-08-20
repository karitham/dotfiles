# dotfiles

The repository contains system and user configuration as a Nix flake. Jujutsu (jj) provides version control.

## Hosts

| Host | Type | Arch | Notes |
|------|------|------|-------|
| kiwi | Laptop | x86_64 | Work — Niri, Waybar, YubiKey, Linear/Sentry MCP |
| belaf | Laptop | x86_64 | Personal — Niri, Secure Boot (Lanzaboote) |
| ozen | WSL | x86_64 | Dev environment on Windows |
| reg | Server | x86_64 | Tailscale, SSH, PDS |
| wakuna | Server | aarch64 | ARM — built as SD image |

## Components

- System: NixOS unstable, Lix, flake-parts, easy-hosts
- User: home-manager, Catppuccin (macchiato)
- Desktop: Niri/Noctalia Shell, Ghostty, Helium browser
- Dev: Nushell, Starship, Atuin, Zellij, Helix (custom fork), Jujutsu, Docker, direnv
- AI: OpenCode with custom agents, skills, MCP (GitHub, Outline, Linear, Sentry)
- Secrets: sops-nix (age)
- Cache: Attic at nix-cache.karitham.dev/dotfiles

## Commands

```bash
nh os switch                    # rebuild & switch (uses ~/dotfiles)
nixos-rebuild switch --flake .#kiwi  # explicit host
nix build .#wakuna-image        # SD image for wakuna
nix fmt                         # format (nixfmt, nufmt, biome)
```

`nh os switch` rebuilds and switches for the current host and assumes the repository at `~/dotfiles`. `nixos-rebuild switch` targets an explicit host. `nix build` produces the `wakuna` image. `nix fmt` formats the repository.

## Repository structure

```
flake.nix              # Flake entry point
flake-parts.nix        # Systems, packages, module exports
modules/
├── core.nix           # my.username, user groups
├── nix.nix            # Lix, Attic cache push
├── locale.nix         # Europe/Paris, en_US + fr_FR
├── home/              # home-manager, Catppuccin
├── desktop/           # Niri/Noctalia, Ghostty, audio, apps
├── dev/               # Nushell, Helix, jj, Docker, OpenCode
├── server/            # Tailscale, SSH
├── wsl/               # NixOS-WSL
├── tags/              # work, secureboot
└── opencode/          # Agents, skills, plugins, commands
systems/
├── default.nix        # easy-hosts definitions
├── kiwi/ belaf/ ozen/ reg/ wakuna/
pkgs/                  # Custom derivations
secrets/               # sops-nix encrypted (age)
```

## Module system

`flake.nix` imports `flake-parts.nix`. `flake-parts.nix` declares supported systems, custom packages, and module exports. `systems/default.nix` declares hosts through [easy-hosts](https://github.com/tgirlcloud/easy-hosts). Each host has a class (`desktop`, `server`, `wsl`) that includes the corresponding module group. Tags (`work`, `secureboot`) add further configuration. `desktop.enable` includes window manager, terminal, audio, applications, and sub-features. `dev.enable` includes shell, editor, version control, tools, OpenCode, and Docker. Each feature provides `nixos.nix` for the system and `home.nix` for the user.

## Secret management

sops-nix with age encryption manages secrets. Files in `secrets/` decrypt at build time. `.sops.yaml` defines keys and creation rules.
