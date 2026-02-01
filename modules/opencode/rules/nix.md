# Nix Best Practices

## Code Style

- Use `nixfmt` for formatting (set as formatter in flake, run `nix fmt` before committing)
- Follow the [Nixpkgs contributing guide](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md) for style conventions
- Use descriptive variable names that explain purpose
- Prefer `let ... in` blocks for local bindings over deep nesting
- Keep derivations and functions small and composable
- Use `lib.mkIf`, `lib.mkWhen`, `lib.optionals` for conditional logic
- Use `lib.getExe` and `lib.getExe'` for accessing package executables

## Error Handling

```nix
# GOOD: Proper error handling with builtins.tryEval
let
  configPath = ./config.json;
  config = builtins.tryEval (builtins.fromJSON (builtins.readFile configPath));
in
if config.success then config.value else throw "Failed to parse config"

# GOOD: Using assert statements for validation
assert lib.assertMsg (cfg.port > 0 && cfg.port < 65536) "Port must be between 1 and 65535";
cfg

# GOOD: Using lib.mapAttrs' with lib.nameValuePair for building attribute sets
lib.mapAttrs' (argName: argValue:
  lib.nameValuePair "${argName}+${dir.name}" {
    action = {
      "${argValue}-${dir.value}" = [ ];
    };
  }
) act

# BAD: Silent failures or incomplete error messages
let
  data = builtins.readFile configPath;
  config = builtins.fromJSON data;  # Will throw cryptic error if invalid
in config
```

## Nix Module System

- Use `lib.mkOptionType`, `lib.mkDefault`, `lib.mkForce` appropriately
- Prefer `mkOption` with proper `type`, `default`, and `description` fields
- Use `mkIf` for conditional module options rather than deep nesting
- Keep modules focused - one module per responsibility
- Use `imports` to compose modules rather than duplicating code
- Use `lib.getExe pkgs.packageName` for executable paths in configuration

```nix
# GOOD: Well-structured module option
{ lib, config, ... }:
{
  options.my.username = lib.mkOption {
    type = lib.types.str;
    description = "The username for the current user.";
    default = "kar";
  };

  config = lib.mkIf (config.my.username != "root") {
    users.users.${config.my.username} = {
      home = "/home/${config.my.username}";
      initialPassword = "";
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "docker"
        "wheel"
      ];
    };
  };
}
```

## Flake Patterns

- Use `flake-parts` for modular flake structure
- Use `withSystem` for system-specific configuration
- Provide `devShells`, `packages`, `checks`, `formatter` per system
- Lock `nixpkgs` reference using channel URLs or specific revisions
- Provide formatter and linter in `devShells`
- Use `nixConfig` for Nix configuration (experimental features, substituters)

## System Management

- Use `easy-hosts` for organizing hosts by class (desktop, server, wsl) and tags
- Define shared modules for all systems in `config.easy-hosts.shared.modules`
- Use perClass and perTag for class-specific and tag-specific modules
- Use `mkSystem'` for creating individual systems with proper specialArgs

## Overlay Patterns

- Use `overrideAttrs` for patching existing packages
- Use `fetchurl` or `fetchFromGitHub` for patches with hash verification
- Use `callPackage` to add packages to overlay
- Keep overlays focused and well-documented

## Package Building

- Use `pkgs.buildGoModule` for Go packages with proper vendorHash
- Use `pkgs.fetchFromGitHub` for GitHub sources with hash verification
- Set `env.CGO_ENABLED`, `flags`, and `ldflags` appropriately for Go
- Include proper `meta` with description, homepage, license, maintainers
- Use `trimpath` and static linking flags for production binaries

## Security

- Never commit secrets or API keys in Nix files
- Use `sops-nix` for secrets management in production
- Use sandbox mode in `nix.conf` (`sandbox = true`) for builds
- Review network access in derivations - use `allowedRequisites` for purity
- Use `fetchFromGitHub` or `fetchurl` with hash verification

## Dependency Management

- Use specific Git revisions/commits for Git dependencies (not branches)
- Always include `sha256` hash for fetch functions
- Use `inputs.nixpkgs.follows` to avoid duplicating inputs
- Pin `nixpkgs` in production configurations using `flake.lock`
- Prefer `flake-inputs` over `builtins.fetchTarball` for external sources
- Use `callPackage` pattern for package dependencies

## Testing

- Use `nix-instantiate --parse` to check for syntax errors
- Use `nix-build` with `-A` to test specific attributes
- Write checks in `perSystem.checks` for package testing
- Use `nix flake check` for flake validation
- Test modules with `nixos-rebuild dry-build` or `nixos-rebuild test`

## Evaluation

- Use `lib.warnIf` and `lib.deprecated` for deprecation notices
- Avoid `builtins.trace` in production code (use for debugging only)
- Use `lib.lists.foldl'` or `lib.lists.foldl'` for strict left folds
- Prefer `lib.mapAttrs` and `lib.mapAttrs'` over `builtins.map` for attribute sets
- Use `lib.filterAttrs` for filtering attributes
- Use `lib.mergeAttrsList` for merging lists of attribute sets
- Use `lib.attrsToList` for converting attributes to list of name-value pairs

## Performance

- Use `lib.optionals` and `lib.concatMap` for list operations
- Avoid deep recursion - use `foldl'` for accumulation
- Use `overrideAttrs` for modifying packages instead of rewriting
- Prefer `stdenv.mkDerivation` over raw `derivation` for packages
- Use `pkgs.callPackage` with explicit arguments for clarity

## Home-Manager Module System

Home-manager modules manage user-level configuration (home directory, user packages, programs).

### Module Structure

```
modules/
  dev/
    home.nix          # Home-manager module with osConfig parameter
    nixos.nix         # NixOS module importing home.nix via homeModules
    shell/
      default.nix      # Imports sub-modules
      nushell.nix      # Actual configuration
```

### Home-Manager Module Pattern

```nix
# modules/dev/shell/default.nix
{
  imports = [
    ./atuin.nix
    ./nushell.nix
    ./starship.nix
    ./zellij.nix
  ];
}
```

### Home-Manager with osConfig

```nix
# modules/dev/home.nix
{
  osConfig ? { },
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  # Inherit options from NixOS module configuration
  config.dev = {
    inherit (osConfig.dev or { })
      shell
      editor
      vcs
      tools
      ;
  };

  # Define options (mirrors NixOS module)
  options.dev = {
    enable = mkEnableOption "all development tools";
    shell.enable = mkEnableOption "shell-related tools";
    editor.enable = mkEnableOption "editor tools";
    vcs.enable = mkEnableOption "version control tools";
    tools.enable = mkEnableOption "development utilities";
  };

  # Import sub-modules
  imports = [
    ./shell
    ./editor
    ./vcs
    ./tools
  ];
}
```

### Flake Integration

```nix
# flake.nix modules section
{
  imports = [ ../systems ];

  perSystem = { ... }: {
    # ...
  };

  flake = {
    homeModules = {
      dev = import ./dev/home.nix;
      desktop = import ./desktop/home.nix;
    };

    nixosModules = {
      dev = import ./dev/nixos.nix;
      desktop = import ./desktop/nixos.nix;
    };
  };
}
```

### Usage in System Configuration

```nix
# systems/kiwi.nix (NixOS)
{
  imports = [
    inputs.self.nixosModules.dev
    # ... other modules
  ];

  dev.enable = true;
  dev.shell.enable = true;
}
```

```nix
# modules/desktop/home.nix (Home-Manager)
{ config, self, ... }:
{
  imports = [
    self.homeModules.dev
    # ... other home modules
  ];

  dev.enable = true;
}
```

### Key Differences from NixOS Modules

| Aspect | NixOS Module | Home-Manager Module |
|--------|--------------|---------------------|
| Special args | `{ config, lib, pkgs, ... }` | `{ config, lib, pkgs, osConfig ? {}, ... }` |
| System config | Direct access to `config.*` | Inherits via `osConfig.dev` |
| User packages | `home.packages` | `home.packages` |
| Programs | `programs.*` | `programs.*` |
| System services | `services.*` | Not available |

### XDG Directories

Home-manager manages XDG directories via `xdg.configFile`, `xdg.dataFile`, etc.:

```nix
{ config, ... }:
{
  xdg.configFile."opencode/agents" = {
    source = ./agents;
    recursive = true;
  };

  programs.opencode = {
    enable = true;
    package = opencodePkg;
    settings = {
      theme = "catppuccin-macchiato";
    };
  };
}
```
