{
  config,
  pkgs,
  ...
}: {
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
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
      gpg.format = "ssh";
      gpg.ssh.defaultKeyCommand = "ssh-add -L";
      core.excludesfile = "~/.gitignore";
      core.editor = config.home.sessionVariables.EDITOR;
      pager.difftool = true;
      diff.tool = "difftastic";
      difftool.prompt = false;
      difftool.difftastic.cmd = "${pkgs.difftastic}/bin/difft --color auto --background light --display side-by-side \"$LOCAL\" \"$REMOTE\"";
      rerere = {
        enabled = true;
        autoUpdate = true;
      };
    };
  };

  home.packages = let
    git-deploy = pkgs.writeShellScriptBin "git-deploy" ''
      if [ $# -ne 1 ]; then
          echo "Usage: git deploy <target-branch>"
          exit 1
      fi

      target=$1
      current=$(git branch --show-current)

      git fetch origin

      # Show commits between current branch and target
      echo "Commits to be deployed:"
      git --no-pager log "origin/$target..$current" --oneline

      read -p "Continue with rebase? (y/n) " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
          git checkout "$target"
          git rebase "$current"
      else
          echo "Rebase cancelled"
      fi
    '';
  in [
    git-deploy
  ];
}
