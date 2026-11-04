{
  config,
  lib,
  inputs',
  ...
}:
{
  options.dev.albedo.enable = lib.mkEnableOption "the Albedo coding agent";

  config = lib.mkIf config.dev.albedo.enable { home.packages = [ inputs'.albedo.packages.default ]; };
}
