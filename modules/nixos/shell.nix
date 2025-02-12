{
  config,
  lib,
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
  };
}
