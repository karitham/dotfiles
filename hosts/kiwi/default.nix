{
  pkgs,
  inputs,
  ...
}: {
  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };
  desktop.enable = true;
  hm.enable = true;
  ipcam.enable = true;
  time.timeZone = "Europe/Paris";

  system = {stateVersion = "24.11";};

  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    ./hardware.nix
  ];

  home-manager.users.kar.imports = [./home-upf.nix ./desktop.nix];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  networking.networkmanager.enable = true;

  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
  };
  services = {
    tailscale.enable = true;
    tailscale.useRoutingFeatures = "client";
    touchegg.enable = true;
    blueman.enable = true;
  };

  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  programs.ssh.startAgent = true;
  environment = with pkgs; {
    systemPackages = [
      signal-desktop
      vscode
      mpv
      sd
      busybox
      moreutils
      gh
    ];
  };
}
