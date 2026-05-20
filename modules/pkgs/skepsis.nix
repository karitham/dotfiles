{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
  makeWrapper,
}:

buildNpmPackage rec {
  pname = "skepsis";
  version = "devel";

  src = fetchFromGitHub {
    owner = "oxidecomputer";
    repo = "skepsis";
    rev = "main";
    hash = "sha256-ovFeshhlkCEnds8sPDsyLf61J9AeO3NJgoIIxHyfuCU=";
  };

  npmDepsHash = "sha256-jXgAjPTrYizn2XP7RXXEzgNhQXWKYaJeZuFsD+2Eh3Q=";

  # Upstream lockfile is missing resolved URLs for ~1/3 of deps (known npm bug).
  # Regenerate it with `npm install --package-lock-only` to fix.
  postPatch = ''
    cp ${./skepsis-lockfile.json} package-lock.json
  '';

  # Frontend is pre-built in dist/, no build step needed
  buildPhase = ''
    runHook preBuild
    runHook postBuild
  '';

  # Keep tsx available at runtime — it's the TypeScript runner for the CLI
  dontNpmPrune = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/skepsis
    cp -r . $out/lib/skepsis

    makeWrapper ${lib.getExe nodejs} $out/bin/sk \
      --add-flags "$out/lib/skepsis/node_modules/tsx/dist/cli.mjs" \
      --add-flags "$out/lib/skepsis/cli.ts"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Local web UI for code review";
    homepage = "https://github.com/oxidecomputer/skepsis";
    license = licenses.mpl20;
    mainProgram = "sk";
  };
}
