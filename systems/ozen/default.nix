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
  my.username = "nixos";
  system.stateVersion = "25.11";
  programs.ssh.startAgent = true;

  nixpkgs.hostPlatform = "x86_64-linux";
}
