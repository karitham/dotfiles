{
  lib,
  gh,
  jujutsu,
  makeWrapper,
  runCommand,
  writers,
}:
let
  # The bare script, for direct testing: `nu gh-prc.nu <pr>`.
  script = writers.writeNu "gh-prc" (builtins.readFile ./gh-prc.nu);
in
# Wrapped so the runtime deps (gh, jj) are on PATH wherever it's installed.
runCommand "gh-prc"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      description = "List PR reviews and inline comments as helix-openable path:line tokens";
      mainProgram = "gh-prc";
      license = lib.licenses.mit;
    };
  }
  ''
    install -Dm755 ${script} $out/bin/gh-prc
    wrapProgram $out/bin/gh-prc --suffix PATH : ${
      lib.makeBinPath [
        gh
        jujutsu
      ]
    }
  ''
