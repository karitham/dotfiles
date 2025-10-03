_: prev: {
  pokego = prev.callPackage ../pkgs/pokego.nix {};
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
  prr = prev.prr.overrideAttrs (_: {
    src = prev.fetchFromGitHub {
      owner = "karitham";
      repo = "prr";
      rev = "e5076af2ab6567a0c738a0dcfeceefd3fe0ce9aa";
      hash = "sha256-jCW/oKrPDTc8Mn7FV7xUMM8m+3bRSBv4iyU4HiOr0Qg=";
    };
    version = "devel";
    cargoHash = "";
  });
}
