# Home-manager side of the dev tools. Enabled by default whenever this
# module is imported; the NixOS-side `dev.enable` is declared in
# ./nixos.nix and set by the class modules (desktop, wsl).
{ lib, ... }: {
  options.dev.enable = lib.mkEnableOption "development tools";

  config.dev.enable = lib.mkDefault true;

  # opencode gates on its own flag; importing the dev bundle turns it on
  # unless overridden (e.g. dev.opencode.sops.enable = false per host).
  config.dev.opencode.enable = lib.mkDefault true;

  imports = [
    ./shell
    ./editor
    ./vcs
    ./tools
    ../opencode
  ];
}
