{ inputs, ... }: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./hardware.nix
    ./pds.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  services.atuin = {
    enable = true;
    host = "0.0.0.0";
  };

  system.stateVersion = "25.05";
}
