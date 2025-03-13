{pkgs, ...}: {
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
      };
      revset-aliases = {
        "immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine())";
      };
      ui = {
        default-command = [
          "log"
          "--no-pager"
          "-r"
          "ancestors(trunk()..) | ::@"
          "-n"
          "10"
        ];
        movement.edit = true;
        editor = "hx";
        diff.tool = [
          "${pkgs.difftastic}/bin/difft"
          "--color=always"
          "$left"
          "$right"
        ];
      };
      aliases = {
        fetch = [
          "util"
          "exec"
          "git"
          "fetch"
          "origin"
        ];
      };
    };
  };
}
