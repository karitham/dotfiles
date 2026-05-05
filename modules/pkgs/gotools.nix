{ pkgs }:
pkgs.gotools.overrideAttrs (_: {
  patches = pkgs.fetchurl {
    url = "https://github.com/karitham/gotools/commit/97818d312ebfc0e879de489035dee88e910fd95d.patch";
    hash = "sha256-2EYyelh/NmeO9PuCr5xlx9HhRrqfEjseXB7WLvdrJes=";
  };
  vendorHash = "sha256-HpWkPsRJ0vCqJi9LoZcVbzeoPQ2B9ftZwuS1r47W7Sc=";
})
