{...}: {
  nixpkgs.overlays = [
    (final: prev: import ./gotools.nix final prev)
  ];
}
