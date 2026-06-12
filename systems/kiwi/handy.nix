{ inputs', lib, ... }: {
  programs.niri.settings.binds = {
    "Mod+Shift+M".action.spawn = [
      (lib.getExe inputs'.handy.packages.handy)
      "--toggle-transcription"
    ];
    "Mod+Shift+N".action.spawn = [
      (lib.getExe inputs'.handy.packages.handy)
      "--toggle-post-process"
    ];
  };
  home.packages = [ inputs'.handy.packages.handy ];
}
