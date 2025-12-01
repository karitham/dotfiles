{pkgs, ...}: {
  programs.opencode = {
    enable = true;
    package = pkgs.symlinkJoin {
      name = "opencode-wrapped";
      paths = [pkgs.opencode];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/opencode \
          --set SHELL ${pkgs.bash}/bin/bash
      '';
    };
  };
}
