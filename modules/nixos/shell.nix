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

    environment.sessionVariables.EDITOR = lib.attrByPath ["home-manager" "users" username "home" "sessionVariables" "EDITOR"] "nano" config;
    programs.nano.enable = !(lib.attrByPath ["home-manager" "users" username "programs" "helix" "enable"] false config);
  };
}
