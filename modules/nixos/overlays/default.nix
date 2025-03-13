{
  inputs,
  # lib,
  ...
}: {
  nixpkgs.overlays = [
    (import ./gotools.nix)
    inputs.helix.overlays.default
  ];
  # nix.settings = {
  #   substituters = lib.mkAfter ["https://helix.cachix.org?priority=100"];
  #   trusted-public-keys = lib.mkAfter ["helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="];
  # };
}
