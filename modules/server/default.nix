_: {
  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };
    openssh.enable = true;
  };
}
