_: prev: {
  pokego = prev.callPackage ../pkgs/pokego.nix { };
  golangci-lint-langserver = prev.golangci-lint-langserver.overrideAttrs (_: {
    patches = prev.fetchurl {
      url = "https://github.com/karitham/golangci-lint-langserver/commit/31e6806187d431a8865261b5441ef5a65b589ae5.patch";
      hash = "sha256-Sw7KCsAhShobhvtwS0KeeWL4ewuXuQYyPeaeHKGUs+I=";
    };
    vendorHash = "sha256-kbGTORTTxfftdU8ffsfh53nT7wZldOnBZ/1WWzN89Uc=";
  });
  gotools = prev.gotools.overrideAttrs (_: {
    patches = prev.fetchurl {
      url = "https://github.com/karitham/gotools/commit/97818d312ebfc0e879de489035dee88e910fd95d.patch";
      hash = "sha256-2EYyelh/NmeO9PuCr5xlx9HhRrqfEjseXB7WLvdrJes=";
    };
    vendorHash = "sha256-UZNYHx5y+kRp3AJq6s4Wy+k789GDG7FBTSzCTorVjgg=";
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
