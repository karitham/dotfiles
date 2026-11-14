# T3 Code's server on its own: the `t3` CLI and the HTTP/ACP server it runs.
#
# `pkgs.t3code` is a symlinkJoin that also carries the Electron desktop app and
# prepends provider CLIs (codex, gh, git, jujutsu) to PATH, which drags electron,
# gtk4 and gstreamer into the closure (~30 GiB). A machine that only runs the
# daemon needs none of that. The server resolves its dependencies from the pnpm
# tree beside `apps/`, so the workspace root's node_modules and apps/server are
# copied; everything else upstream installs is the desktop app.
{ lib
, stdenv
, makeWrapper
, nodejs_26
, t3code
}:

let
  # `t3code` is the wrapped CLI; its passthru keeps the unwrapped output, which
  # is what carries libexec/. Nothing here is taken from the wrapper.
  unwrapped = t3code.unwrapped;
in
stdenv.mkDerivation {
  pname = "t3code-server";
  inherit (unwrapped) version;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  # Vendored prebuilt native artifacts for other platforms confuse both fixups;
  # upstream disables them for the same reason.
  dontPatchELF = true;
  noAuditTmpdir = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/t3code/apps
    cp -r --no-preserve=mode ${unwrapped}/libexec/t3code/node_modules $out/libexec/t3code/
    cp -r --no-preserve=mode ${unwrapped}/libexec/t3code/apps/server $out/libexec/t3code/apps/

    # pnpm links the workspace tree with relative symlinks; the ones pointing at
    # the desktop app dangle once it is left out.
    find $out/libexec/t3code -xtype l -delete

    makeWrapper ${lib.getExe nodejs_26} $out/bin/t3 \
      --add-flags "$out/libexec/t3code/apps/server/dist/bin.mjs"

    runHook postInstall
  '';

  meta = {
    description = "Server and CLI for T3 Code, without the Electron desktop app";
    homepage = "https://github.com/pingdotgg/t3code";
    license = lib.licenses.mit;
    mainProgram = "t3";
    platforms = lib.platforms.linux;
  };
}
