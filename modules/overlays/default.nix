_: prev: {
  pokego = prev.callPackage ../pkgs/pokego.nix { };
  golangci-lint-langserver = prev.golangci-lint-langserver.overrideAttrs (_: {
    patches = prev.fetchurl {
      url = "https://github.com/karitham/golangci-lint-langserver/commit/4a7b5b7ee99a2260c118442304777a8a92a45765.patch";
      hash = "sha256-iMH/4SIDJRq/dPiqC49BBaQX/n7PYX/0+/e0Bv0gPfU=";
    };
    vendorHash = "sha256-kbGTORTTxfftdU8ffsfh53nT7wZldOnBZ/1WWzN89Uc=";
  });
  gotools = prev.gotools.overrideAttrs (_: {
    patches = prev.fetchurl {
      url = "https://github.com/karitham/gotools/commit/97818d312ebfc0e879de489035dee88e910fd95d.patch";
      hash = "sha256-2EYyelh/NmeO9PuCr5xlx9HhRrqfEjseXB7WLvdrJes=";
    };
    vendorHash = "sha256-HpWkPsRJ0vCqJi9LoZcVbzeoPQ2B9ftZwuS1r47W7Sc=";
  });

  # https://github.com/benbjohnson/litestream/issues/912
  litestream = prev.litestream.overrideAttrs (old: {
    version = "devel";
    src = prev.fetchFromGitHub {
      owner = "benbjohnson";
      repo = "litestream";
      rev = "92fc139923d2b13909ba8b0e5df8b63d45a91648";
      sha256 = "sha256-UDyI4pcd8fUdVzvuLBFKifVORYto0yvtMc1pEUY2OaU=";
    };
    vendorHash = "sha256-MFKyECRWvhHwV0NZuuUQ0OYHpyTjRg0vKHuDNzaZJ7c=";
    patches = [ ];
  });
}
