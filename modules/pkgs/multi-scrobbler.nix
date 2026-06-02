{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  importNpmLock,
  jq,
  makeWrapper,
  nodejs_24,
  pkg-config,
  vips,
}:
buildNpmPackage (finalAttrs: {
  pname = "multi-scrobbler";
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "FoxxMD";
    repo = "multi-scrobbler";
    rev = finalAttrs.version;
    hash = "sha256-LkJCh2qPHVjNDf2UCC1ZbBq1Db4/FC2rL0MDeKg1OTc=";
  };

  npmDeps = importNpmLock { npmRoot = "${finalAttrs.src}"; };
  npmConfigHook = importNpmLock.npmConfigHook;

  nodejs = nodejs_24;

  # The docsite has its own package-lock.json and needs sharp (libvips).
  docsiteNodeModules = importNpmLock.buildNodeModules {
    npmRoot = "${finalAttrs.src}/docsite";
    nodejs = nodejs_24;
    derivationArgs = {
      nativeBuildInputs = [ pkg-config ];
      buildInputs = [ vips ];
    };
  };

  npmBuildScript = "build:backend";
  nativeBuildInputs = [
    jq
    makeWrapper
  ];
  env.npm_config_nodedir = nodejs_24;

  postBuild = ''
    npm run build:frontend
    npm run schema:docs

    # Build the Docusaurus site.
    rm -rf docsite/node_modules
    cp -r ${finalAttrs.docsiteNodeModules}/node_modules docsite/

    # @bony_chops/docusaurus-og (social preview images) fails when
    # routeBasePath='/' puts docs at the site root.  The plugin looks
    # for them under build/docs/ — path mismatch.  Drop it.
    jq 'del(.dependencies["@bony_chops/docusaurus-og"])' docsite/package.json > docsite/package.json.tmp
    mv docsite/package.json.tmp docsite/package.json

    sed -i "/import \* as Renderers.*ImageRenderers/d" docsite/docusaurus.config.ts
    line=$(grep -n '@bony_chops/docusaurus-og' docsite/docusaurus.config.ts | cut -d: -f1)
    sed -i "$((line-1)),$((line+8))d" docsite/docusaurus.config.ts

    cd docsite && npm run build
    cd ..
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/${finalAttrs.pname}

    cp package.json $out/share/${finalAttrs.pname}/
    cp -r dist src $out/share/${finalAttrs.pname}/

    # Strip devDependencies and build-time cruft from node_modules.
    npm prune --production
    # ts-json-schema-generator is a build-time tool mis-categorized in
    # "dependencies" upstream. Prune won't remove it, so drop it manually.
    rm -rf node_modules/ts-json-schema-generator
    find node_modules -xtype l -delete || true

    cp -r node_modules $out/share/${finalAttrs.pname}/

    # The app serves the docsite from ./docsite/build/ at runtime.
    mkdir -p $out/share/${finalAttrs.pname}/docsite
    cp -r docsite/build $out/share/${finalAttrs.pname}/docsite/

    makeWrapper ${lib.getExe nodejs_24} $out/bin/${finalAttrs.pname} \
      --chdir $out/share/${finalAttrs.pname} \
      --set NODE_ENV production \
      --set COLORED_STD true \
      --set APP_VERSION ${finalAttrs.version} \
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
})
