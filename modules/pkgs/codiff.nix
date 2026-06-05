{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm,
  electron,
  nodejs,
  cacert,
  makeWrapper,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "codiff";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "nkzw-tech";
    repo = "codiff";
    # v1.1.0 is an annotated tag pointing to this commit.
    rev = "28b1893e58c98f502c5d68f503bfb2548e39b452";
    hash = "sha256-EznBUsTCfRxG7t2YsrvUM0ZqSRlkKha7SVQKkKybmbA=";
  };

  # nixpkgs 26.05 no longer ships buildPnpmPackage; fetch the pnpm store
  # ourselves and let pnpmConfigHook wire it into pnpm install.
  pnpmDeps = fetchPnpmDeps {
    pname = "${finalAttrs.pname}-pnpm-deps";
    inherit (finalAttrs) version src;
    fetcherVersion = 3;
    hash = "sha256-wyivubILGVGcgryizwX41t6zbUNWKz/s9ssrj271EJ4=";
  };

  # electron's npm postinstall downloads its binary; we substitute nixpkgs'
  # electron at runtime by rewriting node_modules/electron/path.txt, so skip
  # the download here.
  ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  nativeBuildInputs = [
    pnpmConfigHook
    makeWrapper
  ];

  buildInputs = [
    nodejs
    pnpm
  ];

  # vite-plus (the Rust-based `vp` build tool) needs a CA bundle to fetch
  # remote modules during the build. Nix's sandbox hides the system one.
  env.SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

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
      --chdir $out/lib/codiff \
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
