{
  pkgs,
  inputs,
  username,
  ...
}: {
  imports = [./hardware.nix];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  services = {
    tailscale.enable = true;
    tailscale.useRoutingFeatures = "server";
    openssh.enable = true;

    atuin = {
      enable = true;
      host = "0.0.0.0";
    };
  };

  users.users = {
    ${username}.openssh.authorizedKeys.keyFiles = [inputs.ssh-keys];
  };

  environment.systemPackages = with pkgs; [helix];

  system = {
    stateVersion = "24.11";
  };
}
