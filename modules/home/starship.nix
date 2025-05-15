{
  inputs',
  lib,
  ...
}: {
  xdg.configFile."starship-jj/starship-jj.toml".text = ''
    "$schema"="https://gitlab.com/Lanastara/lanastara_foss/-/raw/v0.3.0/schema.json?ref_type=tags"
    module_separator = " "
    [bookmarks]
    search_depth = 100
    exclude = []

    [[module]]
    type = "Bookmarks"
    separator = " "
    color = "Magenta"
    behind_symbol = "⇡"

    [[module]]
    type = "Commit"
    max_length = 24

    [[module]]
    type = "State"
    separator = " "

    [module.conflict]
    disabled = false
    text = "(CONFLICT)"
    color = "Red"

    [module.divergent]
    disabled = false
    text = "(DIVERGENT)"
    color = "Cyan"

    [module.empty]
    disabled = false
    text = "(EMPTY)"
    color = "Yellow"

    [module.immutable]
    disabled = false
    text = "(IMMUTABLE)"
    color = "Yellow"

    [module.hidden]
    disabled = false
    text = "(HIDDEN)"
    color = "Yellow"

    [[module]]
    type = "Metrics"
    template = "[{changed} {added}{removed}]"
    color = "Magenta"

    [module.changed_files]
    prefix = ""
    suffix = ""
    color = "Cyan"

    [module.added_lines]
    prefix = "+"
    suffix = ""
    color = "Green"

    [module.removed_lines]
    prefix = "-"
    suffix = ""
    color = "Red"
  '';
  programs.starship = {
    enable = true;
    settings = {
      git_status.disabled = true;
      git_commit.disabled = true;
      git_metrics.disabled = true;
      git_branch.disabled = true;

      # kubernetes.disabled = false;

      custom = {
        jj = {
          command = ''${lib.getExe' inputs'.starship-jj.packages.default "starship-jj"} --ignore-working-copy starship prompt'';
          format = "[$symbol](blue bold) $output ";
          symbol = "󱗆 ";
          when = "jj root --ignore-working-copy";
        };
        git_branch = {
          when = true;
          command = "jj root >/dev/null 2>&1 || starship module git_branch";
          description = "Only show git_branch if we're not in a jj repo";
        };
      };
    };
  };
}
