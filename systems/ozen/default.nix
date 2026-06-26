{ config, ... }: {
  system.stateVersion = "26.05";
  home-manager.users.${config.my.username}.imports = [ ./home.nix ];
  nixpkgs.hostPlatform = "x86_64-linux";
  wsl.useWindowsDriver = true;

  programs = {
    ssh.startAgent = true;
    nix-ld.enable = true;
  };

  environment.etc."ld.so.conf.d/wsl-nvidia.conf".text = ''
    /usr/lib/wsl/lib
  '';

  hardware.nvidia-container-toolkit = {
    enable = true;
    mount-nvidia-executables = false; # https://github.com/nix-community/NixOS-WSL/issues/578
    suppressNvidiaDriverAssertion = true;
  };
}
