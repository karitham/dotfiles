{ ... }: {
  desktop.noctalia.enable = true;
  dev.opencode.sops.enable = false;

  programs.niri.settings.outputs.eDP-1.mode = {
    width = 2560;
    height = 1600;
  };
}
