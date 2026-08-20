# nixpkgs-lib

## Source

- Repo: `NixOS/nixpkgs`
- Book path: `lib/` — there is no separate markdown book. The canonical docs
  are the `/** ... */` doc comments above each function in the `.nix` source
  (signature, type, laws, examples). `lib/README.md` explains the layout:
  each file is a sub-library (e.g. `lib.lists`), and `default.nix` maps the
  top-level aliases (e.g. `lib.take` → `lib.lists.take`).
- URL pattern: `https://raw.githubusercontent.com/NixOS/nixpkgs/{rev}/lib/{file}.nix`
- Rev: grep the repo's `flake.lock` for the `nixpkgs` input node and use its
  `rev` — that is the exact nixpkgs the code evaluates with. If there is no
  `flake.lock`, fall back to the branch `nixos-unstable`.
- README + module map: `lib/README.md`
- Contents API: `https://api.github.com/repos/NixOS/nixpkgs/contents/lib?ref={rev}`
- Rendered manual (same content, generated from those doc comments; may lag
  the pinned rev): `https://nixos.org/manual/nixpkgs/stable/#chap-functions`

Files are ~10–75 KB. Fetch the smallest file that plausibly contains the
function and grep it — do not paste whole files into context.

## Common chapters

| File | Covers |
|---|---|
| `default.nix` | `lib` root: sub-library layout and the full top-level alias map (`lib.take` ⇄ `lib.lists.take`) |
| `attrsets.nix` | `attrByPath`, `hasAttrByPath`, `getAttrFromPath`, `setAttrByPath`, `updateManyAttrsByPath`, `concatMapAttrs`, `mapAttrs`/`mapAttrs'`/`mapAttrsToList`/`mapAttrsRecursive(Cond)`/`mapAttrsToListRecursive`, `genAttrs`/`genAttrs'`, `filterAttrs(Recursive)`, `optionalAttrs`, `mergeAttrsList`, `recursiveUpdate(Until)`, `zipAttrs(With)`, `nameValuePair`, `attrsToList`, `attrValues`, `getOutput`/`getBin`/`getLib`/`getDev`, `overrideExisting`, `showAttrPath`, `isDerivation`, `collect`, `cartesianProduct`, `matchAttrs` |
| `lists.nix` | `optional`/`optionals`, `flatten`, `unique`, `remove`, `subtractLists`, `intersectLists`, `replicate`, `range`, `imap0`/`imap1`, `forEach`, `zipListsWith`, `crossLists`, `foldr`/`foldl`/`foldl'`, `concatMap`/`concatLists`, `partition`, `groupBy`, `toposort`, `all`/`any`/`count`/`elem`/`elemAt`/`take`/`drop`/`head`/`tail`/`init`/`last` |
| `strings.nix` | `concatStringsSep`, `concatMapStrings(Sep)`, `escapeShellArg(s)`, `splitString`, `removePrefix`/`removeSuffix`, `hasPrefix`/`hasSuffix`, `replaceStrings`, `toInt`, `escapeRegex`, `escapeNixString`, `sanitizeDerivationName`, `toUpper`/`toLower`, `versionOlder`/`versionAtLeast`, `toJSON` (alias of `builtins.toJSON`) |
| `strings-with-deps.nix` | `textClosure`, `textList`, `stringAsSet` — dependency-ordered text outputs |
| `customisation.nix` | `callPackageWith`, `callPackagesWith`, `callPackage`, `makeScope`, `makeOverridable` — package-set machinery; the real answer to "recursive callPackage" questions |
| `modules.nix` | Module evaluator core: `mkIf`, `mkMerge`, `mkDefault`, `mkForce`, `mkOverride`, module merge semantics (~75 KB; grep for the specific function) |
| `options.nix` | Option definition helpers: `mkOption`, `mkEnableOption`, `mkPackageOption`, `literalExpression`, `mkSinkUndeclaredOptions` |
| `types.nix` | `types.*` constructors: `str`, `int`, `bool`, `listOf`, `attrsOf`, `enum`, `submodule`, `either`, `nullOr`, `strs`, `lines`, `path`, `package`, `functionTo`, `raw` |
| `trivial.nix` | `id`, `const`, `pipe`, `mergeAttrs`, `flip`, `mapNullable`, `boolToString`, `toHexString`, `checkListOfEnum` |
| `fixed-points.nix` | `fix`, `fix'`, `extends` — recursive (lazy) fixpoints |
| `meta.nix` | `getExe`, `getExe'`, `addMetaAttrs`, `setName`, `lowPrio`/`hiPrio`/`setPrio`, `platformMatch`, `availableOn`, `licensesSpdx`/`getLicenseFromSpdxId` |
| `versions.nix` | `compareVersions` (via builtins), `splitVersion`, `major`/`minor`/`patch`, `majorMinor`, `pad` |
| `generators.nix` | `toYAML`, `toINI`, `toGitINI`, `toKeyValue`, `toLua`, `mkLuaInline`, `toDhall`; legacy `toJSON` shim — use `lib.strings.toJSON` instead |
| `fetchers.nix` | `normalizeHash`, `withNormalizedHash`, `proxyImpureEnvVars`, `fakeHash` — fetchurl/fetchzip helpers |
| `sources.nix` | `lib.sources`: `cleanSource(With)`, `sourceByRegex`, `sourceFilesBySuffices`, `pathIsGitRepo`, `commitIdFromGitRepo`, `pathHasContext`, `trace` |
| `filesystem.nix` | `pathType`, `pathIsDirectory`, `pathIsRegularFile`, `listFilesRecursive`, `locateDominatingFile`, `haskellPathsInDir`, `packagesFromDirectoryRecursive` (readDir-generated package sets) |
| `derivations.nix` | `lazyDerivation`, `optionalDrvAttr`, `warnOnInstantiate` |
| `debug.nix` | `traceIf`, `traceVal(Seq)(N)(Fn)`, `runTests`, `testAllTrue`, `throwTestFailures` |
| `asserts.nix` | `assertMsg`, `assertOneOf`, `assertEachOneOf`, `checkAssertWarn` |
| `cli.nix` | `toGNUCommandLine`, `toGNUCommandLineShell`, `toCommandLine` family — CLI generation from attrsets |