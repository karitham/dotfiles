{
  inputs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64-installer.nix")
    ./torrent.nix
  ];

  sdImage.compressImage = false;
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

  users.users.root.openssh.authorizedKeys.keyFiles = [inputs.ssh-keys];
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };
}
