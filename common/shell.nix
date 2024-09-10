{
  lib,
  pkgs,
  ...
}: {
  options.shell = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "zsh";
      description = "Default shell";
    };
    pkg = lib.mkPackageOption pkgs "zsh" {};
  };
}
