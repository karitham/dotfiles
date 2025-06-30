{
  inputs,
  pkgs,
  ...
}: {
  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };
  desktop.hyprland = true;
  desktop.niri = true;
  ipcam.enable = true;
  yubikey.enable = true;
  time.timeZone = "Europe/Paris";

  system = {
    stateVersion = "25.05";
  };

  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    ./hardware.nix
  ];

  home-manager.users.kar.imports = [
    ./home-upf.nix
    ./desktop.nix
  ];

  boot = {
    # https://gitlab.freedesktop.org/drm/amd/-/issues/3925
    # https://gitlab.freedesktop.org/drm/amd/-/issues/3647
    kernelParams = ["amdgpu.dcdebugmask=0x10"];

    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    binfmt.emulatedSystems = ["aarch64-linux"];
  };

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

  virtualisation.docker.enable = true;

  environment.systemPackages = [
    pkgs.signal-desktop-bin
    pkgs.obs-studio
    pkgs.zed-editor-fhs
  ];
}
