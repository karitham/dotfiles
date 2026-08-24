{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  esbuild,
}:
let
  version = "1.9.10";

  src = fetchFromGitHub {
    owner = "alibaba";
    repo = "open-code-review";
    tag = "v${version}";
    hash = "sha256-/HwWnPtn1CApQEVM6CXheR2LPjU0CCy2X2tciMu+gkM=";
  };

  # OpenCode custom tools use the Zod schema definitions from @opencode-ai/plugin.
  # Bundled into a standalone ESM file so no runtime node_modules resolution is needed.
  npmDeps = fetchNpmDeps {
    name = "open-code-review-tools-npm-deps";
    inherit version;
    src = ./plugin;
    hash = "sha256-gbGsgoJbjqeFeGJJbYjmrede7z8/3dhT0Sy42/dF5kM=";
  };

  toolsBundle = stdenv.mkDerivation {
    pname = "open-code-review-tools";
    inherit version src;

    nativeBuildInputs = [
      npmHooks.npmConfigHook
      nodejs
      esbuild
    ];
    inherit npmDeps;

    prePatch = ''
      cp ${./plugin/package.json} package.json
      cp ${./plugin/package-lock.json} package-lock.json
      cp ${./plugin/ocr-tools.ts} ocr-tools.ts
    '';

    buildPhase = ''
      esbuild ocr-tools.ts \
        --bundle --format=esm --platform=node \
        --outfile=ocr.js
    '';

    installPhase = ''
      mkdir -p $out/share/opencode/tools
      install -m644 ocr.js $out/share/opencode/tools/ocr.js
    '';
  };
in
buildGoModule {
  pname = "open-code-review";
  inherit version src;

  vendorHash = "sha256-RdIDGoDx/aIqm7gD2acHi9THVjZg5DkNU0y2S/cHm28=";

  # Mirror upstream release builds: static, stripped, version-stamped.
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X main.Version=v${version}"
  ];

  subPackages = [ "cmd/opencodereview" ];

  # The unit tests shell out to `git init`; not worth wiring a check
  # environment for a locally-packaged tool.
  doCheck = false;

  postInstall = ''
    mv $out/bin/opencodereview $out/bin/ocr

    mkdir -p $out/share/opencode/tools $out/share/opencode/commands
    cp ${toolsBundle}/share/opencode/tools/* $out/share/opencode/tools/
    install -m644 ${./commands/ocr-review.md} $out/share/opencode/commands/ocr-review.md
    install -m644 ${./commands/ocr-health.md} $out/share/opencode/commands/ocr-health.md
    install -m644 ${./commands/delegate-review.md} $out/share/opencode/commands/delegate-review.md
  '';

  passthru = {
    commands = {
      ocr-review = ./commands/ocr-review.md;
      ocr-health = ./commands/ocr-health.md;
      delegate-review = ./commands/delegate-review.md;
    };
  };

  meta = with lib; {
    description = "AI-powered code review CLI";
    homepage = "https://github.com/alibaba/open-code-review";
    changelog = "https://github.com/alibaba/open-code-review/releases/tag/v${version}";
    license = licenses.asl20;
    mainProgram = "ocr";
    platforms = platforms.linux;
    maintainers = with maintainers; [ karitham ];
  };
}
