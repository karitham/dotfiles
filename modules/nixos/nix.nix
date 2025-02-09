{
  inputs,
  pkgs,
  ...
}: {
  nix = {
    package = pkgs.lix;

    settings = {
      trusted-users = ["root" inputs.username];
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      warn-dirty = false;
    };
  };

  nixpkgs = {
    overlays = [
      (import ../../overlays/gotools.nix)
    ];
    config = {
      allowUnfree = true;
      input-fonts.acceptLicense = true;
    };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/${inputs.username}/dotfiles";
  };
}
