_: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
    stdlib = ''
      alias() {
      	if [ ! $PWD/.direnv/bin ]; then
      		mkdir $PWD/.direnv/bin
      	fi

      	echo "#!/usr/bin/env sh
      $2 \$@" > "$PWD/.direnv/bin/$1"
      	chmod +x "$PWD/.direnv/bin/$1"
      }
    '';
  };

  programs.nushell.extraConfig = ''
    $env.DIRENV_LOG_FORMAT = ""
  '';
}
