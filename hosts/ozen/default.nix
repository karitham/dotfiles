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
  ];

  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };

  virtualisation.docker.enable = true;
  hm.enable = true;

  environment.sessionVariables = {
    EDITOR = "hx";
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
