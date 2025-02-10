{inputs, ...}: {
  nixpkgs.overlays = [
    (final: prev: import ./gotools.nix final prev)
    (final: prev: {ghostty = inputs.stable.legacyPackages.${prev.system}.ghostty;})
  ];
}
