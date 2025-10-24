{
  lib,
  stdenv,
  tree-sitter,
  topiary,
  makeWrapper,
  runCommand,
  fetchFromGitHub,
}: let
  treeSitterWithLatestNu = tree-sitter.override {
    extraGrammars = {
      tree-sitter-nu = {
        url = "https://github.com/nushell/tree-sitter-nu";
        rev = "18b7f951e0c511f854685dfcc9f6a34981101dd6";
        sha256 = "sha256-OSazwPrUD7kWz/oVeStnnXEJiDDmI7itiDPmg062Kl8=";
        fetchSubmodules = false;
      };
    };
  };

  treeSitterNu = treeSitterWithLatestNu.builtGrammars.tree-sitter-nu;

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
