# Shared home-manager base, used by both the NixOS `home-manager.users` path
# (via ./default.nix) and the standalone `homeConfigurations` generated in
# ../../flake-parts.nix. Keep machine-agnostic content here; per-machine bits
# live in systems/<host>/home.nix.
{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.catppuccin.homeModules.default ];

  # Mirror of modules/core.nix's identity option: the NixOS and HM module
  # trees are separate, so each declares its own copy of `my`.
  options.my.username = lib.mkOption {
    type = lib.types.str;
    description = "The username for the current user.";
  };

  config = {
    my.username = lib.mkDefault "kar";

    home = {
      username = config.my.username;
      homeDirectory = lib.mkDefault "/home/${config.my.username}";
      stateVersion = "26.05";
      enableNixpkgsReleaseCheck = false;
    };

    catppuccin = {
      enable = true;
      flavor = "macchiato";
      autoEnable = true;
      cache.enable = true;
    };

    manual = {
      html.enable = false;
      json.enable = false;
      manpages.enable = false;
    };

    sops.age.sshKeyPaths = [ "/home/${config.my.username}/.ssh/id_ed25519" ];
  };
}
