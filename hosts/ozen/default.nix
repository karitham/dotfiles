{
  inputs,
  pkgs,
  lib,
  username,
  ...
}: let
  inherit (lib) mkForce;
in {
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    inputs.nixos-wsl.nixosModules.default
    {
      system.stateVersion = "24.11";
      wsl.enable = true;
      wsl.defaultUser = "nixos";
    }
  ];

  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };

  virtualisation.docker.enable = true;

  programs = {
    ssh.startAgent = true;
  };

  services = {
    smartd.enable = mkForce false;
    xserver.enable = mkForce false;
  };

  networking.tcpcrypt.enable = mkForce false;

  # resolv.conf is managed by wsl
  services.resolved.enable = mkForce false;
  security.apparmor.enable = mkForce false;

  environment = {
    variables.BROWSER = mkForce "wsl-open";
    systemPackages = [pkgs.wsl-open];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
