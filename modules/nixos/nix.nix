{
  inputs,
  pkgs,
  ...
}: {
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
        "recursive-nix"
        "ca-derivations"
      ];
    };
  };

  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";

  imports = [./overlays];

  nixpkgs = {
    config = {
      allowUnfree = true;
      input-fonts.acceptLicense = true;
    };
  };

  system.switch = {
    enable = false;
    enableNg = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 15d --keep 5";
    flake = "/home/${inputs.username}/dotfiles";
  };
}
