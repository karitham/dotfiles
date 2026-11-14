{ config, ... }: {
  home-manager.users.${config.my.username}.imports = [ ./home.nix ];

  # The user services here (albedo, and the T3 Code daemon other devices pair
  # with) answer the tailnet, not just a terminal: start the user manager at
  # boot instead of at the first login.
  users.users.${config.my.username}.linger = true;

  system.stateVersion = "26.05";
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
