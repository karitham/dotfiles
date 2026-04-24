{
  config,
  lib,
  inputs,
  ...
}:
{
  my.username = lib.mkDefault "root";

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };
    openssh.enable = true;
  };

  users.users.${config.my.username}.openssh.authorizedKeys.keyFiles = lib.mkIf (inputs ? ssh-keys) [ inputs.ssh-keys ];
}
