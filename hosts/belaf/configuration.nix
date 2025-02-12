{pkgs, ...}: {
  # Bootloader.
  boot.supportedFilesystems = ["bcachefs"];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
  };
  services = {
    tailscale.enable = true;
    tailscale.useRoutingFeatures = "client";

    # touchpad
    touchegg.enable = true;

    # bluetooth
    blueman.enable = true;

    # udev
    udev.packages = [pkgs.via];
  };

  hardware.keyboard.qmk.enable = true;

  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  programs.ssh.startAgent = true;
  environment = with pkgs; {
    systemPackages = [
      legcord
      vscode
      fzf
      sd
      mpv
      busybox
      moreutils
      age
      wireguard-tools
    ];
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
    data-root = "/docker";
  };
}
