{
  inputs,
  username,
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (!config.server) {
    nix = {
      package = pkgs.lix;

      registry.nixpkgs.flake = inputs.nixpkgs;
      channel.enable = false;

      settings = {
        auto-optimise-store = true;
        builders-use-substitutes = true;
        allowed-users = ["@wheel"];
        trusted-users = ["@wheel"];
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

    environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";

    nixpkgs = {
      config = {
        allowUnfree = true;
        input-fonts.acceptLicense = true;
      };
      overlays = [
        inputs.self.overlays.default
        inputs.niri.overlays.niri
      ];
    };

    programs.nh = {
      enable = true;
      flake = "/home/${username}/dotfiles";
    };
  };
}
