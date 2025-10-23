{
  lib,
  stdenv,
  fetchFromGitHub,
  tree-sitter,
  nodejs,
  topiary,
  makeWrapper,
  runCommand,
}:

let
  treeSitterNu = stdenv.mkDerivation {
    name = "tree-sitter-nu";
    src = fetchFromGitHub {
      owner = "nushell";
      repo = "tree-sitter-nu";
      rev = "18b7f951e0c511f854685dfcc9f6a34981101dd6";
      hash = "sha256-OSazwPrUD7kWz/oVeStnnXEJiDDmI7itiDPmg062Kl8=";
    };

    buildInputs = [
      tree-sitter
      nodejs
    ];

    buildPhase = ''
      tree-sitter generate --abi=14
    '';

    installPhase = ''
      mkdir -p $out/lib
      if [[ -e src/scanner.c ]]; then
        $CC -fPIC -c src/scanner.c -o scanner.o -Isrc -O2
      fi
      $CC -fPIC -c src/parser.c -o parser.o -Isrc -O2
      $CC -shared -o $out/lib/tree_sitter_nu.so *.o
    '';
  };

  topiaryNushell = fetchFromGitHub {
    owner = "blindFS";
    repo = "topiary-nushell";
    rev = "fd78be393af5a64e56b493f52e4a9ad1482c07f4";
    hash = "sha256-5gmLFnbHbQHnE+s1uAhFkUrhEvUWB/hg3/8HSYC9L14=";
  };

  configDir = stdenv.mkDerivation {
    name = "topiary-nu-config";
    src = topiaryNushell;

    buildPhase = ''
      mkdir -p $out
      cat <<EOF > $out/languages.ncl
      {
        languages = {
          nu = {
            extensions = ["nu"],
            grammar.source.path = "${treeSitterNu}/lib/tree_sitter_nu.so"
          },
        },
      }
      EOF
    '';

    installPhase = ''
      cp -r $src/languages $out
    '';
  };
in
runCommand "topiary-nu" {
  buildInputs = [ makeWrapper ];
  meta = {
    mainProgram = "topiary-nu";
  };
} ''
  mkdir -p $out/bin
  makeWrapper ${lib.getExe topiary} $out/bin/topiary-nu \
    --set TOPIARY_LANGUAGE_DIR "${configDir}/languages" \
    --set TOPIARY_CONFIG_FILE "${configDir}/languages.ncl"
''