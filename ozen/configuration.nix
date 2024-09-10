{config, pkgs, ...}: {
  shell.name = "nu";
  shell.pkg = pkgs.nushell;

  users.users.nixos.extraGroups = ["docker"];
  users.defaultUserShell = config.shell.pkg;
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
    fzf
  ];
}
