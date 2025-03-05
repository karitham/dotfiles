{
  config,
  lib,
  pkgs,
  ...
}: {
  options.ipcam.enable = lib.mkEnableOption "enable ipcam module";

  config = lib.mkIf (config.desktop.enable && config.ipcam.enable) {
    boot = {
      extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
      kernelModules = ["v4l2loopback"];
      extraModprobeConfig = ''
        options v4l2loopback video_nr=9 card_label=IP-Webcam exclusive_caps=1
      '';
    };

    environment.systemPackages = [pkgs.ffmpeg];
  };
}
