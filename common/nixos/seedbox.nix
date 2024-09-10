{pkgs, ...}: {
  nixpkgs.config = {
    allowUnfree = true;
  };

  services.plex.openFirewall = true;
  services.plex.enable = true;
  services.plex.user = "rtorrent";

  services.radarr.openFirewall = true;
  services.radarr.enable = true;

  services.sonarr.openFirewall = true;
  services.sonarr.enable = true;

  services.rtorrent.openFirewall = true;
  services.rtorrent.enable = true;

  # jesec-flood for ui
  systemd.services.flood = {
    enable = true;
    description = "flood";
    after = [
      "network.target"
    ];
    wantedBy = [
      "multi-user.target"
    ];

    serviceConfig = {
      Type = "simple";
      User = "rtorrent";
      ExecStart = "${pkgs.flood}/bin/flood --port=2323 --host=0.0.0.0";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
