{
  config,
  lib,
  username,
  pkgs,
  ...
}: {
  config = lib.mkIf (!config.server) {
    users.defaultUserShell = pkgs.nushell;
    environment.shells = [pkgs.nushell];

    environment.sessionVariables.EDITOR =
      lib.mkIf (
        config ? home-manager
      )
      config.home-manager.users.${username}.home.sessionVariables.EDITOR;
  };
}
