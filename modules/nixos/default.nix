{...}: {
  imports = [
    ./shell.nix
    ./ipcam.nix
    ./desktop.nix
    ./sound.nix
    ./nix.nix
    ./cachix.nix
    ./locale.nix
    ./docker.nix
    ./fonts.nix
    ./yubikey.nix
    ./server.nix
  ];
}
