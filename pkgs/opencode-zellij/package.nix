# OpenCode V2 port of opencode-zellij (upstream: maou-shonen/opencode-zellij).
#
# Source is vendored here (runtime only; tests and dev tooling are omitted) and
# built hermetically with tsdown. The output is a plugin *directory*: OpenCode
# V2 loads a local plugin directory through an index file inside it, so only the
# two build outputs are installed.
{ lib, buildNpmPackage }:
buildNpmPackage {
  pname = "opencode-zellij";
  version = "0.1.1";

  src = ./.;

  npmDepsHash = "sha256-9O7ucZAmQyC993xa44Rl5t5vFFePtyvZwqXfULPSJdU=";

  # Two self-contained files (node builtins only), not the node package layout.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    install -m644 dist/index.mjs $out/index.mjs
    install -m644 dist/pane-watchdog-runner.mjs $out/pane-watchdog-runner.mjs
    runHook postInstall
  '';

  meta = {
    description = "OpenCode V2 plugin: run long-lived commands in visible Zellij panes";
    homepage = "https://github.com/maou-shonen/opencode-zellij";
    license = lib.licenses.mit;
  };
}
