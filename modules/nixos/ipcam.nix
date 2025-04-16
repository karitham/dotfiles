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

    environment.systemPackages = let
      port = 9696;
      ipcam = pkgs.writeShellScriptBin "ipcam" ''
        ${lib.getExe' pkgs.android-tools "adb"} wait-for-usb-device
        ${lib.getExe' pkgs.android-tools "adb"} forward tcp:${toString port} tcp:8080
        ${lib.getExe pkgs.ffmpeg} -i http://localhost:${toString port}/video -vf format=yuv420p -f v4l2 /dev/video9
        ${lib.getExe' pkgs.android-tools "adb"} forward --remove tcp:${toString port}
      '';
    in [
      pkgs.ffmpeg
      pkgs.android-tools
      ipcam
    ];
  };
}
