{
  lib,
  stdenv,
  tree-sitter,
  topiary,
  makeWrapper,
  runCommand,
  nodejs,
  tree-sitter-nu,
  topiary-nushell,
}: let
  treeSitterNu = stdenv.mkDerivation {
    name = "tree-sitter-nu";
    src = tree-sitter-nu;
    buildInputs = [tree-sitter nodejs];
    buildPhase = ''
      tree-sitter generate
      gcc -o parser.so -Isrc src/parser.c src/scanner.c -shared -fPIC -O2
    '';
    installPhase = ''
      mkdir -p $out
      cp parser.so $out/parser
    '';
  };

  configDir = stdenv.mkDerivation {
    name = "topiary-nu-config";
    src = topiary-nushell;

    buildPhase = ''
      mkdir -p $out
      cat <<EOF > $out/languages.ncl
      {
        languages = {
          nu = {
            extensions = ["nu"],
            grammar.source.path = "${treeSitterNu}/parser"
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
    buildInputs = [makeWrapper];
    meta = {
      mainProgram = "topiary-nu";
    };
  } ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe topiary} $out/bin/topiary-nu \
      --set TOPIARY_LANGUAGE_DIR "${configDir}/languages" \
      --set TOPIARY_CONFIG_FILE "${configDir}/languages.ncl"
  ''
