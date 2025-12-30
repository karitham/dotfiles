{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    ../../modules/home
    ./hardware.nix
  ];

  yubikey.enable = true;
  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };
  time.timeZone = "Europe/Paris";
  desktop.enable = true;
  system.stateVersion = "25.11";

  home-manager.users.kar.imports = [
    ./home-upf.nix
    ./desktop.nix
  ];

  boot = {
    # https://gitlab.freedesktop.org/drm/amd/-/issues/3925
    # https://gitlab.freedesktop.org/drm/amd/-/issues/3647
    # kernelParams = ["amdgpu.dcdebugmask=0x10"];

    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
  };

  hardware = {
    keyboard.qmk.enable = true;
  };

  networking.networkmanager.enable = true;

  services = {
    tailscale.enable = true;
    tailscale.useRoutingFeatures = "client";
    touchegg.enable = true;
    blueman.enable = true;
    auto-cpufreq.enable = true;
    udev.packages = [pkgs.via];
  };

  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  virtualisation.docker.enable = true;

  programs._1password.enable = true;
}
