{
  config,
  lib,
  inputs,
  ...
}:
{
  my.username = "root";

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };
    openssh.enable = true;
  };

  users.users.${config.my.username}.openssh.authorizedKeys.keyFiles = lib.optionals (inputs ? ssh-keys) [
    inputs.ssh-keys
  ];
}
