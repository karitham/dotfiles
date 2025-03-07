{
  config,
  pkgs,
  ...
}: {
  home.packages = [pkgs.gh];
  programs.git = {
    enable = true;
    userName = "karitham";
    userEmail = "kar@karitham.dev";

    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };

    aliases = {
      co = "checkout";
      ci = "commit";
      st = "status";
      br = "branch";
      hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";
      type = "cat-file -t";
      dump = "cat-file -p";
      dft = "difftool";
    };

    extraConfig = {
      init.defaultBranch = "main";
      merge.stat = true;
      pull.rebase = true;

      push = {
        autoSetupRemote = true;
        default = "current";
      };

      url."ssh://git@github.com/".insteadOf = "https://github.com/";

      gpg = {
        format = "ssh";
        ssh.defaultKeyCommand = "ssh-add -L";
      };

      core = {
        excludesfile = "~/.gitignore";
        editor = config.home.sessionVariables.EDITOR;
        whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
      };

      pager.difftool = true;
      diff.tool = "difftastic";
      difftool = {
        prompt = false;
        difftastic.cmd = "${pkgs.difftastic}/bin/difft --color auto --background light --display side-by-side \"$LOCAL\" \"$REMOTE\"";
      };

      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };

      rerere = {
        enabled = true;
        autoUpdate = true;
      };
    };
  };
}
