{inputs, ...}: {
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    inputs.nixos-wsl.nixosModules.default
    {
      system.stateVersion = "24.11";
      wsl.enable = true;
      wsl.defaultUser = "nixos";
    }
  ];

  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };

  virtualisation.docker.enable = true;

  programs = {
    ssh.startAgent = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
