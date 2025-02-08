{
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
}
