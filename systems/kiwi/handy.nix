{ inputs', lib, ... }:
{
  programs.niri.settings.binds."Mod+Shift+M".action.spawn = [
    (lib.getExe inputs'.handy.packages.handy)
    "--toggle-transcription"
  ];
  home.packages = [ inputs'.handy.packages.handy ];
}
