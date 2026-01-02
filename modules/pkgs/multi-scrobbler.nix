{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
  makeWrapper,
  bashNonInteractive,
  ...
}:
buildNpmPackage rec {
  pname = "multi-scrobbler";
  version = "0.10.8";

  src = fetchFromGitHub {
    owner = "FoxxMD";
    repo = "multi-scrobbler";
    rev = version;
    hash = "sha256-knHOAE5reDN7fVmA2guQFG49jiQobzLpFlm6N1TioSI=";
  };

  npmDepsHash = "sha256-4do1Hm6c82v0I2N7eO700k4rOBjLOx373QKKuhi5/uU=";

  nativeBuildInputs = [
    makeWrapper
    bashNonInteractive
  ];

  inherit nodejs;

  buildPhase = ''
    runHook preBuild

    npm run build:backend
    npm run build:frontend

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    npm prune --production

    mkdir -p $out/bin $out/share/multi-scrobbler
    cp -r * $out/share/multi-scrobbler/

    runHook postInstall
  '';

  postInstall = ''
    # Copy tsconfig for ts-json-schema-generator to find at runtime
    # The app expects tsconfig.json to be in the working directory under src/backend/
    # We'll preserve the source directory structure
    mkdir -p $out/share/multi-scrobbler/src/backend
    cp src/backend/tsconfig.json $out/share/multi-scrobbler/src/backend/

    # Create wrapper with working directory set to the source install location
    makeWrapper ${nodejs}/bin/node $out/bin/multi-scrobbler \
      --add-flags "$out/share/multi-scrobbler/node_modules/tsx/dist/cli.mjs" \
      --add-flags "$out/share/multi-scrobbler/src/backend/index.ts" \
      --chdir "$out/share/multi-scrobbler"
  '';

  meta = with lib; {
    description = "Scrobble plays from multiple sources to multiple clients";
    homepage = "https://github.com/FoxxMD/multi-scrobbler";
    license = licenses.mit;
    mainProgram = "multi-scrobbler";
  };
}
