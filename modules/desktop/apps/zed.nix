{ lib, config, ... }:
{
  config = lib.mkIf (config.dev.tools.enable || false) { programs.zed-editor.enable = true; };
}
