{pkgs, ...}: {
  services.upower.enable = true;
  environment = with pkgs; {
    systemPackages = [
      wl-clipboard
      waybar
      wlroots
      dunst
      xdg-utils
      xdg-desktop-portal-hyprland
      pavucontrol
      killall
      playerctl
      brightnessctl
      upower
      pulseaudio
      gnome-themes-extra
    ];
  };
}
