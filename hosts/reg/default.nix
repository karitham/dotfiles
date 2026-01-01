{
  config,
  pkgs,
  inputs,
  ...
}:
{
  my.username = "root";

  imports = [
    inputs.sops-nix.nixosModules.sops
    ./hardware.nix
    ./pds.nix
    ./pds-backup.nix
    ./multi-scrobbler.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  services.atuin = {
    enable = true;
    host = "0.0.0.0";
  };

  users.users = {
    ${config.my.username}.openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys ];
  };

  environment.systemPackages = with pkgs; [ helix ];

  system.stateVersion = "25.05";
}
