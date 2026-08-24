{ inputs', lib, ... }:
let
  handy = inputs'.handy.packages.default;
in
{
  programs.niri.settings.binds = {
    "Mod+M".action.spawn = [
      (lib.getExe handy)
      "--toggle-transcription"
    ];
    "Mod+N".action.spawn = [
      (lib.getExe handy)
      "--toggle-post-process"
    ];
  };
  home.packages = [ handy ];
}
