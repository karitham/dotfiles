{
  lib,
  buildNpmPackage,
  fetchurl,
}:
buildNpmPackage {
  pname = "browsermcp";
  version = "0.1.3";
  src = fetchurl {
    url = "https://registry.npmjs.org/@browsermcp/mcp/-/mcp-0.1.3.tgz";
    hash = "sha256-KtNMKRRcqAxfLn2OyQ4FiWl7GTOLK0WoPJGNSQekz5Y=";
  };

  # The published tarball has no lockfile and its devDependencies reference
  # monorepo workspace packages (`workspace:*`) that npm cannot resolve
  # standalone. dist/ ships prebuilt, so dev deps are dropped and the
  # production lockfile is committed next to this file.
  postPatch = ''
    cp ${./browsermcp-lock.json} package-lock.json
    # npm ci rejects the workspace:*-protocol devDependencies even with
    # --omit=dev, so strip them from package.json. fetchNpmDeps also runs
    # postPatch but only needs the lockfile and has no node on PATH.
    if command -v node >/dev/null; then
      node -e 'const fs = require("fs"); const p = JSON.parse(fs.readFileSync("package.json")); delete p.devDependencies; fs.writeFileSync("package.json", JSON.stringify(p, null, 2))'
    fi
  '';

  npmDepsHash = "sha256-f5asiKwV6pg7V0B2Yt391QbtVrYptwYtUioxBK2uJpU=";

  dontNpmBuild = true;

  # `npm pack` would run the `prepare` script (npm run build); devDeps are
  # stripped and dist/ is prebuilt, so skip it.
  npmPackFlags = [ "--ignore-scripts" ];

  postInstall = ''
    mkdir -p $out/bin
    ln -sf $out/lib/node_modules/@browsermcp/mcp/dist/index.js $out/bin/mcp-server-browsermcp
  '';

  meta = with lib; {
    description = "MCP server for browser automation using Browser MCP";
    homepage = "https://browsermcp.io";
    license = licenses.asl20;
    mainProgram = "mcp-server-browsermcp";
    maintainers = with maintainers; [ karitham ];
  };
}
