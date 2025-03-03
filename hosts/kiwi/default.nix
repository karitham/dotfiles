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
  ipcam.enable = true;
  yubikey.enable = true;
  time.timeZone = "Europe/Paris";

  system = {
    stateVersion = "24.11";
  };

  # https://gitlab.freedesktop.org/drm/amd/-/issues/3925
  # https://gitlab.freedesktop.org/drm/amd/-/issues/3647
  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x10"
  ];

  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    ./hardware.nix
  ];

  home-manager.users.kar.imports = [
    ./home-upf.nix
    ./desktop.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  networking.networkmanager.enable = true;

  services = {
    tailscale.enable = true;
    tailscale.useRoutingFeatures = "client";
    touchegg.enable = true;
    blueman.enable = true;
    auto-cpufreq.enable = true;
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
