{...}: {
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
      };
      ui = {
        default-command = ["log" "-r" "..@" "-n" "10" "--no-pager"];
      };
    };
  };
}
