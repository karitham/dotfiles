_: {
  imports = [ ../../modules/home ];

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

  virtualisation.docker.enable = true;
}
