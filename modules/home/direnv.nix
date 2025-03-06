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
      use_wg() {
        if [[ $1 ]] ; then
          wg-quick up $1
        else
          wg-quick up ./*.conf
        fi
      }
    '';
  };

  programs.nushell.extraConfig = ''
    $env.DIRENV_LOG_FORMAT = ""
  '';
}
