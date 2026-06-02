{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs_24,
}:

buildNpmPackage rec {
  pname = "multi-scrobbler";
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "FoxxMD";
    repo = "multi-scrobbler";
    rev = version;
    hash = "sha256-LkJCh2qPHVjNDf2UCC1ZbBq1Db4/FC2rL0MDeKg1OTc=";
  };

  npmDepsHash = "sha256-1IUvjfYeM1GaK1OeSLoq8YSDjuS3rR+cgtwxgbbU5ps=";
  npmBuildScript = "build:backend";
  nativeBuildInputs = [ makeWrapper ];
  env.npm_config_nodedir = nodejs_24;

  postBuild = ''
    npm run build:frontend
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/${pname}

    cp package.json package-lock.json $out/share/${pname}/
    cp -r dist src $out/share/${pname}/
    cp -r node_modules $out/share/${pname}/

    rm -rf $out/share/${pname}/.git
    rm -rf $out/share/${pname}/docsite/node_modules
    rm -rf $out/share/${pname}/node_modules/ts-json-schema-generator
    rm -f $out/share/${pname}/node_modules/.bin/ts-json-schema-generator

    makeWrapper ${lib.getExe nodejs_24} $out/bin/${pname} \
      --chdir $out/share/${pname} \
      --set NODE_ENV production \
      --set COLORED_STD true \
      --set APP_VERSION ${version} \
      --add-flags ./node_modules/.bin/tsx \
      --add-flags ./src/backend/index.ts

    runHook postInstall
  '';

  meta = {
    description = "Scrobble plays from multiple sources to multiple clients";
    homepage = "https://github.com/FoxxMD/multi-scrobbler";
    license = lib.licenses.mit;
    mainProgram = "multi-scrobbler";
  };
}
