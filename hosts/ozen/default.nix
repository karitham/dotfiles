{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    inputs.nixos-wsl.nixosModules.default
    {
      system.stateVersion = "24.05";
      wsl.enable = true;
      wsl.defaultUser = "nixos";
    }
    inputs.home-manager.nixosModules.home-manager
    ./hm.nix
    ../../modules/fonts.nix
    ../../modules/shell.nix
    ../../modules/nixos/nix.nix
  ];

  shell = {
    name = "nu";
    pkg = pkgs.nushell;
  };

  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };

  networking.hostName = inputs.hostname;
  users.users.nixos = {
    extraGroups = ["docker"];
  };
  virtualisation = {
    docker.enable = true;
  };

  programs = {
    nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs;
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    ssh.startAgent = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
