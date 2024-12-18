{
  config,
  pkgs,
  ...
}: {
  config = {
    boot.extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
    boot.kernelModules = ["v4l2loopback"];
    boot.extraModprobeConfig = ''
      options v4l2loopback video_nr=9 card_label=IP-Webcam exclusive_caps=1
    '';

    environment.systemPackages = [
      pkgs.v4l-utils
      pkgs.ffmpeg
    ];
  };
}
