{pkgs, ...}: {
  users.users.nixos.extraGroups = ["docker"];
  users.defaultUserShell = pkgs.zsh;
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      plugins = ["sudo" "zsh-navigation-tools" "zoxide"];
    };
  };
  virtualisation.docker.enable = true;

  services.openssh.enable = true;

  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;
  programs.nix-ld.package = pkgs.nix-ld-rs;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.ssh.startAgent = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];
  environment.systemPackages = with pkgs; [
    curl
    openssh
    jq
    wget
    zoxide
  ];
}
