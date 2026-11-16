# T3 Code from an upstream nightly.
#
# nixpkgs packages 0.1.8, which refuses `/compact` for ACP agents: its
# acpRegistry flavor never wired compaction, so the client answers "This
# provider does not support context compaction." before the agent sees the
# prompt. pingdotgg/t3code#28822 fixed that on 2026-11-12 and it ships in the
# nightlies only, so carry one here until nixpkgs has a release with it.
{ pkgs }:
let
  version = "0.1.10-nightly.20261116.4787";
  src = pkgs.fetchFromGitHub {
    owner = "pingdotgg";
    repo = "t3code";
    tag = "v${version}";
    hash = "sha256-K46Lp9oc90zhPnbBB7nzqMjJUJcOxXKmPelzzG76UG4=";
  };
  nixpkgsT3Code = "${pkgs.path}/pkgs/by-name/t3/t3code";
  # Same build the nixpkgs derivation describes, over a different source: keep
  # every flag, rebuild the two hashes it pins.
  unwrapped = (pkgs.callPackage "${nixpkgsT3Code}/unwrapped.nix" { }).overrideAttrs (old: {
    inherit version src;
    pnpmDeps = pkgs.fetchPnpmDeps {
      pnpm = pkgs.pnpm_12;
      inherit (old) pname pnpmWorkspaces;
      inherit version src;
      fetcherVersion = 5;
      hash = "sha256-27Ljt2lY4J1Fi3ddVIflPQ5erRqmgaZ8+YBH9fhCLzo=";
    };
  });
in
pkgs.callPackage "${nixpkgsT3Code}/package.nix" { t3code-unwrapped = unwrapped; }
