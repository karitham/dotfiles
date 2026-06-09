{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  nix = {
    package = pkgs.lix;

    registry.nixpkgs.flake = inputs.nixpkgs;
    registry.self.flake = inputs.self;
    channel.enable = false;

    settings = {
      auto-optimise-store = true;
      builders-use-substitutes = true;
      allowed-users = [ "@wheel" ];
      trusted-users = [ "@wheel" ];
      commit-lockfile-summary = "chore: Update flake.lock";
      accept-flake-config = true;
      keep-derivations = true;
      keep-outputs = true;
      warn-dirty = false;

      sandbox = true;
      max-jobs = "auto";
      keep-going = true;
      log-lines = 20;
      extra-experimental-features = [
        "flakes"
        "nix-command"
      ];
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      input-fonts.acceptLicense = true;
    };
  };

  programs.nh = {
    enable = true;
    flake = "/home/${config.my.username}/dotfiles";
  };

  environment = {
    etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
    systemPackages = with pkgs; [ attic-client ];
  };

  systemd.services.attic-push = {
    description = "Push NixOS system closure to Attic cache";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.attic-client}/bin/attic push dotfiles /run/current-system";
      User = "root";
      Group = "root";
    };
  };

  system.activationScripts.attic-push = pkgs.lib.mkAfter ''
    ${lib.getExe' pkgs.systemd "systemctl"} start attic-push.service || true
  '';
}
