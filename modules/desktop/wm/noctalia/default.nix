{
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkIf config.desktop.noctalia.enable {
    qt = {
      enable = true;
      style.name = "kvantum";
    };

    programs.niri.settings = {
      spawn-at-startup = [ { command = [ (lib.getExe config.programs.noctalia.package) ]; } ];

      binds = {
        "Alt+Space".action.spawn = [
          "noctalia"
          "msg"
          "panel-toggle"
          "launcher"
        ];
      };
    };

    programs.noctalia = {
      enable = true;
      settings = {
        bar.widgets = {
          auto_hide = true;
          margin_ends = 10;
          reserve_space = false;
          start = [
            "launcher"
            "workspaces"
          ];
        };

        control_center.shortcuts = [
          { type = "wifi"; }
          { type = "bluetooth"; }
          { type = "power_profile"; }
          { type = "audio"; }
        ];

        dock.enabled = false;

        location.auto_locate = true;

        lockscreen_widgets = {
          enabled = false;
          schema_version = 2;
          grid = {
            cell_size = 16;
            major_interval = 4;
            visible = true;
          };
        };

        notification = {
          monitors = [ "eDP-1" ];

          # Helium sends YouTube Music "now scrobbling" notifications with
          # app_name "Helium", so the app token cannot distinguish them. Match
          # the body header instead and keep the toast while dropping the sound
          # and the history entry.
          filter."youtube-music" = {
            enabled = true;
            match_content = "^YouTube Music";
            show_toast = true;
            save_history = false;
            play_sound = false;
          };
        };

        osd.monitors = [ "eDP-1" ];
        plugins.enabled = [ ];

        shell = {
          animation.speed = 2.0;
          font_family = "Lexend";
          offline_mode = true;
          password_style = "random";
        };

        theme = {
          builtin = "Catppuccin";

          templates = {
            enable_builtin_templates = false;
            enable_community_templates = false;
          };
        };

        wallpaper = {
          enabled = true;
          default.path = config.desktop.wallpaper.image;
        };
      };
    };
  };
}
