{ pkgs }:
pkgs.golangci-lint-langserver.overrideAttrs (_: {
  patches = pkgs.fetchurl {
    url = "https://github.com/karitham/golangci-lint-langserver/commit/4a7b5b7ee99a2260c118442304777a8a92a45765.patch";
    hash = "sha256-iMH/4SIDJRq/dPiqC49BBaQX/n7PYX/0+/e0Bv0gPfU=";
  };
  vendorHash = "sha256-kbGTORTTxfftdU8ffsfh53nT7wZldOnBZ/1WWzN89Uc=";
})
