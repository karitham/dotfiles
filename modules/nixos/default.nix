{...}: {
  imports = [
    ./shell.nix
    ./ipcam.nix
    ./desktop.nix
    ./displayManager.nix
    ./sound.nix
    ./nix.nix
    ./cachix.nix
    ./locale.nix
    ./docker.nix
    ./fonts.nix
    ./yubikey.nix
  ];
}
