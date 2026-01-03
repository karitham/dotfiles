{ config, self, ... }:
{
  imports = [
    self.nixosModules.desktop
    self.nixosModules.dev
    ../../modules/home
    ../locale.nix
    ../nix.nix
    ../cachix.nix
    ../hardware/peripherals.nix
  ];

  desktop.enable = true;
  dev.enable = true;

  networking.networkmanager.enable = true;

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
    touchegg.enable = true;
    blueman.enable = true;
    auto-cpufreq.enable = true;
  };

  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  home-manager.users.${config.my.username}.imports = [
    self.homeModules.desktop
    self.homeModules.dev
  ];
}
