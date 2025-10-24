{
  pkgs,
  inputs,
  username,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./hardware.nix
    ./pds.nix
    ./pds-backup.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
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
  server = true;

  system.stateVersion = "25.05";
}
