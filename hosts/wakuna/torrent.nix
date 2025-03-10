{config, ...}: {
  systemd.services.flood.serviceConfig = {
    SupplementaryGroups = [config.services.rtorrent.group];
  };
  services = {
    flood = {
      enable = true;
      host = "::";
    };
    rtorrent = {
      enable = true;
    };
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };
}
