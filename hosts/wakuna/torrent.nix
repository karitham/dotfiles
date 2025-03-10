_: {
  systemd.services.flood.serviceConfig = {
    SupplementaryGroups = ["rtorrent"];
  };
  services = {
    flood = {
      enable = true;
      host = "::";
    };
    rtorrent = {
      enable = true;
    };
  };
}
