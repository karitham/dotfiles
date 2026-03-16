{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.dev.shell.enable {
    home.packages = [ pkgs.jj-starship ];
    programs.starship = {
      enable = true;
      settings = {
        format = lib.concatMapStrings (s: s) [
          "$directory"
          "$nix_shell"
          "$custom"
          "$cmd_duration"
          "$line_break"
          "$character"
        ];
        nix_shell = {
          format = "[$symbol]($style)";
        };
        custom = {
          jj = {
            when = "jj-starship detect";
            shell = [ "jj-starship" ];
            format = "$output ";
          };
        };
        git_branch = {
          disabled = true;
        };
        git_status = {
          disabled = true;
        };
      };
    };
  };
}
