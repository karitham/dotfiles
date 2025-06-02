{
  pkgs,
  inputs,
  username,
  ...
}: {
  imports = [./hardware.nix];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  services = {
    tailscale.enable = true;
    tailscale.useRoutingFeatures = "server";
    openssh.enable = true;

    atuin = {
      enable = true;
      host = "0.0.0.0";
    };

    writefreely = {
      enable = true;
      host = "notes.0xf.fr";
      nginx.enable = true;
      acme.enable = true;
      settings = {
        server.port = 3003;
        app.host = "https://notes.0xf.fr";
        app.site_name = "writefreely";
        app.site_description = "writefreely";
        app.single_user = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];

  security.acme = {
    defaults.email = "netop@0xf.fr";
    acceptTerms = true;
  };

  users.users = {
    ${username}.openssh.authorizedKeys.keyFiles = [inputs.ssh-keys];
  };

  environment.systemPackages = with pkgs; [helix writefreely];
  server = true;

  system = {
    stateVersion = "25.05";
  };
}
