_: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      alias() {
        mkdir -p .direnv/bin
        echo "#!/usr/bin/env sh
        $(which $2) \$@" >.direnv/bin/$1
        chmod +x .direnv/bin/$1
      }
    '';
  };

  programs.nushell.extraConfig = ''
    $env.DIRENV_LOG_FORMAT = ""
  '';
}
