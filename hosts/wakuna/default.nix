{
  inputs,
  lib,
  modulesPath,
  config,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64-installer.nix")
    ./torrent.nix
  ];

  sdImage.compressImage = false;
  my.username = "root";
  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "24.11";

  boot = {
    supportedFilesystems.zfs = lib.mkForce false;
    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb_storage"
    ];
  };

  users.users.${config.my.username}.openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys ];

  services.openssh.settings.PermitRootLogin = "yes";
}
