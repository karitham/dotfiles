{
  lib,
  osConfig,
  pkgs,
  ...
}: let
  hyprland-catpuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "hyprland";
    rev = "b57375545f5da1f7790341905d1049b1873a8bb3";
    hash = "sha256-XTqpmucOeHUgSpXQ0XzbggBFW+ZloRD/3mFhI+Tq4O8=";
  };
in {
  config = lib.mkIf osConfig.desktop.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        source = [
          "${hyprland-catpuccin}/themes/macchitao.conf"
        ];

        "$accent" = "$mauve";
        "$accentAlpha" = "$mauveAlpha";
        "$font" = osConfig.fonts.mono;

        # GENERAL
        general = {
          disable_loading_bar = true;
          hide_cursor = true;
        };

        background = {
          monitor = "";
          path = "${osConfig.desktop.wallpaper}";
          blur_passes = 0;
          color = "$base";
        };

        # LAYOUT
        label = [
          {
            monitor = "";
            text = "Layout: $LAYOUT";
            color = "$text";
            font_size = 25;
            font_family = "$font";
            position = "30, -30";
            halign = "left";
            valign = "top";
          }
          {
            monitor = "";
            text = "$TIME";
            color = "$text";
            font_size = 90;
            font_family = "$font";
            position = "-30, 0";
            halign = "right";
            valign = "top";
          }

          {
            text = "cmd[update:43200000] date +\"%A, %d %B %Y\"";
            color = "$text";
            font_size = 25;
            font_family = "$font";
            position = "-30, -150";
            halign = "right";
            valign = "top";
          }
        ];

        # INPUT FIELD
        input-field = {
          monitor = "";
          size = "300, 60";
          outline_thickness = 4;
          dots_size = 0.2;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = "$accent";
          inner_color = "$surface0";
          font_color = "$text";
          fade_on_empty = false;
          placeholder_text = ''<span foreground="##$textAlpha"><i>󰌾 Logged in as </i><span foreground="##$accentAlpha">$USER</span></span>'';
          hide_input = false;
          check_color = "$accent";
          fail_color = "$red";
          fail_text = ''<i>$FAIL <b>($ATTEMPTS)</b></i>'';
          capslock_color = "$yellow";
          position = "0, -47";
          halign = "center";
          valign = "center";
        };
      };
    };
  };
}
