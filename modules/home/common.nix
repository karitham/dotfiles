# Shared home-manager base, used by both the NixOS `home-manager.users` path
# (via ./default.nix) and the standalone `homeConfigurations` generated in
# ../../flake-parts.nix. Keep machine-agnostic content here; per-machine bits
# live in systems/<host>/home.nix.
{ inputs, ... }: {
  imports = [ inputs.catppuccin.homeModules.default ];

  home = {
    username = "kar";
    stateVersion = "26.05";
    enableNixpkgsReleaseCheck = false;
  };

  catppuccin = {
    enable = true;
    flavor = "macchiato";
    autoEnable = true;
  };

  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

  sops.age.sshKeyPaths = [ "/home/kar/.ssh/id_ed25519" ];
  dev.opencode.sops.enable = true;
}
