{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  system.stateVersion = "25.11";
  programs.ssh.startAgent = true;

  nixpkgs.hostPlatform = "x86_64-linux";
}
