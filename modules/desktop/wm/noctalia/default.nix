{
  inputs,
  config,
  osConfig,
  lib,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkIf osConfig.desktop.noctalia.enable {
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

        location.address = "Lille";
        weather.enabled = true;

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
          enable_daemon = false;
        };

        osd = {
          monitors = [ "DP-1" ];
        };

        plugins = {
          enabled = [ ];
        };

        shell = {
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
