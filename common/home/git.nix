{pkgs, ...}: {
  programs.git = {
    enable = true;
    userName = "Karitham";
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
      pull.rebase = true;
      push.autoSetupRemote = true;
      url."git@github.com:".insteadOf = "https://github.com/";
      gpg.format = "ssh";
      gpg.ssh.defaultKeyCommand = "ssh-add -L";
      core.excludesfile = "~/.gitignore";
      core.editor = "hx";
      pager.difftool = true;
      diff.tool = "difftastic";
      difftool.prompt = false;
      difftool.difftastic.cmd = "${pkgs.difftastic}/bin/difft --color auto --background light --display side-by-side \"$LOCAL\" \"$REMOTE\"";
    };
  };
}
