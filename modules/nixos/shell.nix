{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  options.shell = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "nu";
      description = "Default shell";
    };
    pkg = lib.mkPackageOption pkgs "nushell" {};
  };

  config = {
    users.defaultUserShell = config.shell.pkg;
    environment.shells = ["${config.shell.pkg}/bin/${config.shell.name}"];
    environment.sessionVariables.EDITOR = lib.mkIf config.hm.enable config.home-manager.users.${inputs.username}.home.sessionVariables.EDITOR;
  };
}
