{
  config,
  pkgs,
  ...
}: let
  ik = pkgs.buildGoModule {
    name = "ik";
    modRoot = "./go";

    src = pkgs.fetchFromGitHub {
      owner = "devguardio";
      repo = "identity";
      rev = "60af40a194bc38b27a02986012ee721219e068e1";
      sha256 = "sha256-IuoTS3wvK4vQIJAAsrBmLjkiBC/wQuGOOxjtPPJpE8g=";
    };

    subPackages = ["ik"];
    vendorHash = "sha256-Ow7Hctv4UNAYQN/IwsV4o4xIUcJz3fJuO4yasj6+lH8=";
  };
in {
  environment.systemPackages = [ik pkgs.wireguard-tools];
  environment.etc = {
    "fabric/config.json".text = ''{"consume_bgp":false}'';
  };
  systemd.services.fabric = {
    enable = true;
    unitConfig = {StartLimitIntervalSec = 1;};
    serviceConfig = {
      WorkingDirectory = "${config.users.users.kar.home}/.fab";
      ExecStart = "${config.users.users.kar.home}/.fab/fabric run";
      Restart = "always";
    };
    path = with pkgs; [ik sysctl nftables];
    wantedBy = ["multi-user.target"];
  };
}
