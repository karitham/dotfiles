{
  lib,
  fetchPnpmDeps,
  fetchgit,
  pnpm_9,
  makeWrapper,
  nodejs,
  pnpmConfigHook,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "malachite";
  version = "0.6.2";

  src = fetchgit {
    url = "https://tangled.org/ewancroft.uk/atproto-lastfm-importer";
    rev = "10ae8f794a2066702ddbbcd11326664ede844879";
    hash = "sha256-do2B348lUIkSaQfMCoVMcpi031BdfpzUXetyY2S17nI=";
    deepClone = false;
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_9
    makeWrapper
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_9;
    fetcherVersion = 3;
    hash = "sha256-Y94PgzvxLZcSiK4sBrxm1KrBhOLh1QXaJpuFstl4RSk=";
  };

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/malachite
    cp -r . $out/lib/node_modules/malachite

    makeWrapper ${nodejs}/bin/node $out/bin/lastfm-import \
      --add-flags "$out/lib/node_modules/malachite/dist/index.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Import your Last.fm listening history to the AT Protocol network using the fm.teal.alpha.feed.play lexicon";
    homepage = "https://tangled.org/ewancroft.uk/atproto-lastfm-importer";
    license = licenses.mit;
    mainProgram = "lastfm-import";
  };
})
