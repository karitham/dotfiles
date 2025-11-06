_: {
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
        auto-local-bookmark = true;
        write-change-id-header = true;
        track-default-bookmark-on-clone = true;
      };
      revsets = {
        log = "..@ | branches | curbranch::@ | @::nextbranch | downstream(@, branchesandheads)";
      };
      revset-aliases = {
        "immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine())";
        "downstream(x,y)" = "(x::y) & y";
        "branches" = "downstream(trunk(), bookmarks()) & mine()";
        "branchesandheads" = "branches | (heads(trunk()::) & mine())";
        "curbranch" = "latest(branches::@- & branches)";
        "nextbranch" = "roots(@:: & branchesandheads)";
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
}
