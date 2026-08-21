# Home-manager side of the dev tools. Enabled by default whenever this
# module is imported; the NixOS-side `dev.enable` is declared in
# ./nixos.nix and set by the class modules (desktop, wsl).
{ lib, ... }: {
  options.dev.enable = lib.mkEnableOption "development tools";

  config.dev.enable = lib.mkDefault true;

  imports = [
    ./shell
    ./editor
    ./vcs
    ./tools
    ../opencode
  ];
}
