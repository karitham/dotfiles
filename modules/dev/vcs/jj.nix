{ config, lib, ... }: {
  config = lib.mkIf config.dev.enable {
    programs.jujutsu = {
      enable = true;

      settings = {
        user = {
          email = "kar@karitham.dev";
          name = "karitham";
        };
        signing = {
          behavior = "own";
          backend = "ssh";
          key = "~/.ssh/id_ed25519.pub";
        };
        git = {
          write-change-id-header = true;
          track-default-bookmark-on-clone = true;
        };
        remotes."origin".auto-track-bookmarks = "glob:*";
        revsets = {
          log = "..@ | branches | curbranch::@ | @::nextbranch | downstream(@, branchesandheads)";
          bookmark-advance-to = "closest_pushable(@)";
        };
        aliases = {
          tug = [
            "bookmark"
            "advance"
          ];
          push = [
            "git"
            "push"
          ];
        };
        revset-aliases = {
          "immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine())";
          "downstream(x,y)" = "(x::y) & y";
          "branches" = "downstream(trunk(), bookmarks()) & mine()";
          "branchesandheads" = "branches | (heads(trunk()::) & mine())";
          "curbranch" = "latest(branches::@- & branches)";
          "nextbranch" = "roots(@:: & branchesandheads)";
          "top" = "heads(mine())";
          "closest_pushable(to)" = "heads(::to & mutable() & ~description(exact:\"\") & (~empty() | merges()))";
        };
        ui = {
          default-command = [
            "log"
            "--no-pager"
            "-n"
            "10"
          ];
          movement.edit = true;
          editor = "hx";
        };
      };
    };

    programs.delta = {
      enable = true;
      enableJujutsuIntegration = true;
      enableGitIntegration = true;
    };
  };
}
