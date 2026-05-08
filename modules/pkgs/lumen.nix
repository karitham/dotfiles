{
  buildGoModule,
  fetchFromGitHub,
  lib,
  pkgs,
}:
buildGoModule rec {
  pname = "lumen";
  version = "0.0.39";

  src = fetchFromGitHub {
    owner = "ory";
    repo = "lumen";
    rev = "v${version}";
    hash = "sha256-Q3oby96ClaU3fDgKHFgwR0WxGIGFJpJuTJ+s65bmC6w=";
  };

  vendorHash = "sha256-uPYc9sDWT4sxsxrXe3mqzUeC9UOEJLkRcFF2v9dOx44=";

  subPackages = [ "." ];

  env = {
    CGO_ENABLED = 1;
    CGO_CFLAGS = "-I ${lib.getDev pkgs.sqlite}/include";
  };

  tags = [ "fts5" ];

  nativeBuildInputs = [ ];

  # go-tree-sitter bundles tree-sitter C source. Subpackage C files
  # include internal headers as "tree_sitter/parser.h" but the headers
  # live at the module root, not under a tree_sitter/ prefix.
  # Create a tree_sitter -> .. symlink in each subdirectory so
  # relative includes (#include "tree_sitter/parser.h") resolve.
  postConfigure = ''
    local tsDir="vendor/github.com/smacker/go-tree-sitter"
    if [ -d "$tsDir" ]; then
      chmod -R u+w "$tsDir"
      for dir in "$tsDir"/*/; do
        [ -d "$dir" ] && ln -sf .. "$dir/tree_sitter"
      done
    fi
  '';

  meta = with lib; {
    description = "Semantic code search engine for AI coding agents";
    homepage = "https://github.com/ory/lumen";
    license = licenses.asl20;
    mainProgram = "lumen";
    platforms = platforms.linux;
  };
}
