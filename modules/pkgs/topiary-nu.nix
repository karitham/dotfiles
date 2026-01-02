{
  lib,
  writeShellApplication,
  topiary,
  nushell,
  tree-sitter-grammars,
  writeText,
  linkFarm,
  pkgs, # otherwise lint issue because `fetchurl` is a builtin
}:
let
  langDir = linkFarm "topiary-nu-languages" [
    {
      name = "nu.scm";
      path = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/blindFS/topiary-nushell/main/languages/nu.scm";
        hash = "sha256-2o7oIFkxuy8u8HNkiEzNnoKekmwaxClCWQnQg3rgVeU=";
      };
    }
  ];
  configFile = writeText "languages.json" (
    builtins.toJSON {
      languages = {
        nu = {
          extensions = [ "nu" ];
          grammar.source.path = "${tree-sitter-grammars.tree-sitter-nu}/parser";
        };
      };
    }
  );
in
writeShellApplication {
  name = "topiary-nu";
  runtimeInputs = [
    nushell
    topiary
  ];
  runtimeEnv = {
    TOPIARY_CONFIG_FILE = configFile;
    TOPIARY_LANGUAGE_DIR = langDir;
  };
  text = ''
    ${lib.getExe topiary} "$@"
  '';
}
