{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkForce;
in {
  my.username = "nixos";

  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    inputs.nixos-wsl.nixosModules.default
    ../../modules/home
  ];

  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };
  wsl.enable = true;
  wsl.defaultUser = config.my.username;
  system.stateVersion = "25.11";

  virtualisation.docker.enable = true;

  programs.ssh.startAgent = true;

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
