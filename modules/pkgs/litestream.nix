{ pkgs, fetchFromGitHub }:
pkgs.litestream.overrideAttrs (old: {
  # https://github.com/benbjohnson/litestream/issues/912
  version = "devel";
  src = fetchFromGitHub {
    owner = "benbjohnson";
    repo = "litestream";
    rev = "92fc139923d2b13909ba8b0e5df8b63d45a91648";
    sha256 = "sha256-UDyI4pcd8fUdVzvuLBFKifVORYto0yvtMc1pEUY2OaU=";
  };
  vendorHash = "sha256-MFKyECRWvhHwV0NZuuUQ0OYHpyTjRg0vKHuDNzaZJ7c=";
  patches = [ ];
})
