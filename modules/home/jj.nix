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
        sign-on-push = true;
        auto-local-bookmark = true;
      };
      revset-aliases = {
        "immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine())";
      };
      ui = {
        default-command = [
          "log"
          "--no-pager"
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
      "--scope" = [
        {
          "--when".repositories = ["~/upf"];
          revset-aliases."immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine()) | master@origin | staging@origin";
        }
      ];
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
