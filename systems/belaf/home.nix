{ ... }: {
  dev.enable = true;
  desktop.enable = true;
  desktop.noctalia.enable = true;

  programs.niri.settings.outputs.eDP-1.mode = {
    width = 2560;
    height = 1600;
  };
}
