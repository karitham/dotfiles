{
  pkgs,
  ssh-keys,
  ...
}: {
  nix.settings = {
    trusted-users = ["root"];
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
  };
  imports = [./hardware.nix];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "reg";

  services = {
    tailscale.enable = true;
    tailscale.useRoutingFeatures = "server";
    openssh.enable = true;
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config = {allowUnfree = true;};
  };

  users.users = {
    root.openssh.authorizedKeys.keyFiles = [ssh-keys];
  };
  environment.systemPackages = with pkgs; [
    tailscale
    helix
    curl
    wget
    jq
  ];

  system = {stateVersion = "24.05";};
}
