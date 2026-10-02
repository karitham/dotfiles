{
  lib,
  buildNpmPackage,
  fetchurl,
}:
buildNpmPackage {
  pname = "chrome-devtools-mcp";
  version = "1.10.1";
  src = fetchurl {
    url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-1.10.1.tgz";
    hash = "sha256-ASy89ugy1PZwna0MIde+8XCJ6Ure6c8zF50V6gqa3ys=";
  };

  # The published tarball ships the rollup bundle in build/ but no lockfile, and
  # its devDependencies (puppeteer, typescript, rollup, ...) only exist to rebuild
  # that bundle. Drop them so npm resolves an empty tree — the runtime is fully
  # bundled — and commit the prod-only lockfile next to this file.
  postPatch = ''
    cp ${./chrome-devtools-mcp-lock.json} package-lock.json
    # npm ci rejects devDependencies that the lockfile doesn't cover, so strip them
    # from package.json. fetchNpmDeps also runs postPatch but only needs the
    # lockfile and has no node on PATH.
    if command -v node >/dev/null; then
      node -e 'const fs = require("fs"); const p = JSON.parse(fs.readFileSync("package.json")); delete p.devDependencies; fs.writeFileSync("package.json", JSON.stringify(p, null, 2))'
    fi
    # With an empty lockfile npm installs nothing and never creates node_modules,
    # which npmInstallHook's fixup then fails to find.
    mkdir -p node_modules
  '';

  npmDepsHash = "sha256-Ged5rkAk0Bv1ZvtUPMyhv2zAAAG+AeL3HSFwdIOcvAo=";

  # The bundle carries its own runtime, so the resolved tree is empty by design.
  forceEmptyCache = true;

  # `npm run build` needs the stripped devDeps (tsc, rollup) and `prepare` needs
  # the repo's scripts/ dir, neither of which the tarball ships. build/ is
  # prebuilt, so skip both.
  dontNpmBuild = true;

  # `npm pack` would run `prepare` (node scripts/prepare.ts); skip it.
  npmPackFlags = [ "--ignore-scripts" ];

  meta = {
    description = "MCP server giving agents control of a live Chrome instance";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = lib.licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
  };
}
