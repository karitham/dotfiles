{
  lib,
  pkgs,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm,
  electron,
  nodejs,
  cacert,
  git,
  makeWrapper,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "codiff";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "karitham";
    repo = "codiff";
    rev = "add-opencode-backend";
    hash = "sha256-AtYPn/hD0GKKlBASMQ79R5R9qRLTAHwyXv7AaTtORAI=";
  };

  pnpmDeps = fetchPnpmDeps {
    pname = "${finalAttrs.pname}-pnpm-deps";
    inherit (finalAttrs) version src;
    fetcherVersion = 3;
    hash = "sha256-wyivubILGVGcgryizwX41t6zbUNWKz/s9ssrj271EJ4=";
  };

  env = {
    # Skip pnpm's electron download;
    # installPhase rewrites node_modules/electron/path.txt to nixpkgs' electron store path.
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

    # vite-plus (the Rust-based `vp` build tool) needs a CA bundle to fetch
    # remote modules during the build. Nix's sandbox hides the system one.
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

    # pnpm refuses to clean its modules dir without a TTY; we're in a non-TTY
    # sandbox, so opt into CI behaviour.
    CI = "true";
  };

  nativeBuildInputs = [
    pnpmConfigHook
    makeWrapper
  ];

  buildInputs = [
    nodejs
    pnpm
    git
  ];

  # pnpmConfigHook (via postConfigureHooks) already ran `pnpm install --offline
  # --ignore-scripts --frozen-lockfile` and patched shebangs. We now need to
  # run the install scripts for native modules (@swc/core, @tailwindcss/oxide)
  # that the hook skipped, then build. Electron's postinstall is intentionally
  # skipped (ELECTRON_SKIP_BINARY_DOWNLOAD=1) — we substitute nixpkgs' electron
  # at install time.
  buildPhase = ''
    runHook preBuild
    pnpm rebuild @swc/core @tailwindcss/oxide
    pnpm exec vp build
    runHook postBuild
  '';

  # Run the unit tests via vite-plus. Runs after buildPhase so dist/ is in
  # place. The full test suite is fast enough that we always run it as part
  # of the build — failing tests should fail the package.
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    pnpm test
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/codiff $out/bin
    cp -r . $out/lib/codiff

    # The `electron` npm module reads `path.txt` for the *relative* binary
    # name inside its `dist/` directory. Codiff spawns whatever it imports.
    # We set ELECTRON_OVERRIDE_DIST_PATH to ${electron}/bin so that the
    # import resolves to nixpkgs' electron wrapper (which sets GTK/GIO
    # env vars and execs the unwrapped binary). printf avoids the trailing
    # newline that `echo` would add (the module doesn't trim).
    printf 'electron' > $out/lib/codiff/node_modules/electron/path.txt

    makeWrapper ${lib.getExe nodejs} $out/bin/codiff \
      --set ELECTRON_OVERRIDE_DIST_PATH ${electron}/bin \
      --add-flags $out/lib/codiff/bin/codiff.js

    # Desktop entry + icon. Use the absolute icon path in the .desktop file
    # rather than a bare name — bypasses icon-theme discovery entirely,
    # which was failing for the hicolor lookup in some DE setups.
    install -Dm644 electron/icons/icon.png $out/share/icons/hicolor/1024x1024/apps/codiff.png
    mkdir -p $out/share/applications
    cat > $out/share/applications/codiff.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Codiff
    Comment=Fast local diff viewer
    Exec=codiff %U
    Icon=$out/share/icons/hicolor/1024x1024/apps/codiff.png
    Categories=Development;Utility
    Terminal=false
    StartupNotify=true
    EOF

    runHook postInstall
  '';

  # Strip the `opencode/skills/` prefix so the output shape matches the other
  # symlinkJoin'd skills (each top-level entry is a skill name).
  passthru.opencodeSkill = pkgs.runCommand "codiff-opencode-skill" { } ''
    mkdir -p $out/codiff
    cp -r ${finalAttrs.src}/opencode/skills/codiff/. $out/codiff/
    chmod -R +w $out/codiff
  '';

  meta = with lib; {
    description = "Fast local diff viewer";
    homepage = "https://github.com/nkzw-tech/codiff";
    license = licenses.mit;
    mainProgram = "codiff";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
})
