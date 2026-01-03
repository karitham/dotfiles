{
  inputs,
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    self.nixosModules.dev
    inputs.nixos-wsl.nixosModules.default
    ../locale.nix
    ../home
    ../nix.nix
    ../cachix.nix
  ];

  dev.enable = true;

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
    smartd.enable = mkForce false;
    xserver.enable = mkForce false;
    resolved.enable = mkForce false;
  };

  wsl = {
    enable = true;
    defaultUser = config.my.username;
  };

  environment = {
    variables.BROWSER = mkForce "wsl-open";
    systemPackages = [ pkgs.wsl-open ];
  };

  networking.tcpcrypt.enable = mkForce false;

  security = {
    apparmor.enable = mkForce false;
    sudo.wheelNeedsPassword = false;
  };

  home-manager.users.${config.my.username}.imports = [ self.homeModules.dev ];
}
