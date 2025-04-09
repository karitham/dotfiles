{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (osConfig.desktop.enable && osConfig.desktop.niri) {
    programs.niri = {
      settings = {
        environment = {
          NIXOS_OZONE_WL = "1";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          QT_QPA_PLATFORMTHEME = "qt5ct";
          QT_QPA_PLATFORM = "wayland";
          DISPLAY = ":0";
        };

        screenshot-path = null;

        input = {
          focus-follows-mouse = {
            enable = true;
            max-scroll-amount = "80%";
          };
          keyboard = {
            repeat-delay = 150;
            repeat-rate = 30;
            xkb = {
              layout = "us";
              variant = "intl";
            };
          };

          mouse = {
            accel-profile = "flat";
            accel-speed = 0.5;
          };

          touchpad = {
            tap = true;
            dwt = true;
            natural-scroll = true;
            click-method = "clickfinger";
          };
        };

        spawn-at-startup = [
          {
            command = [
              "systemctl --user restart waybar.service"
            ];
          }
        ];

        layout = {
          gaps = 16;
          always-center-single-column = true;
          empty-workspace-above-first = true;
          default-column-width = {proportion = 0.5;};
        };

        window-rules = [
          {
            geometry-corner-radius = let
              radius = 8.0;
            in {
              bottom-left = radius;
              bottom-right = radius;
              top-left = radius;
              top-right = radius;
            };
            clip-to-geometry = true;
          }
        ];

        outputs = rec {
          eDP-1 = {
            mode = null;
            position = {
              x = HDMI-A-1.mode.width;
              y = 0;
            };
          };
          HDMI-A-1 = {
            mode = {
              width = 2560;
              height = 1440;
            };
            position = {
              x = 0;
              y = 0;
            };
          };
        };

        binds = with config.lib.niri.actions; let
          # programs.niri.settings.binds."Mod+Q".action.close-window = []
          toAction = act: dir: (lib.mapAttrs' (argName: argValue: lib.nameValuePair "${argName}+${dir.name}" {action = {"${argValue}-${dir.value}" = [];};}) act);
          windowMoves = lib.mergeAttrsList (
            (
              map (toAction {
                "Mod" = "focus";
                "Mod+Ctrl" = "move";
              }) (lib.attrsToList {
                "Up" = "window-up";
                "Down" = "window-down";
                "Left" = "column-left";
                "Right" = "column-right";
                "I" = "workspace-down";
                "U" = "workspace-up";
              })
            )
            ++ (
              map (toAction {
                "Mod+Shift" = "focus";
                "Mod+Ctrl+Shift" = "move-window-to";
              }) (lib.attrsToList {
                "Up" = "monitor-up";
                "Down" = "monitor-down";
                "Left" = "monitor-left";
                "Right" = "monitor-right";
                "I" = "workspace-down";
                "U" = "workspace-up";
              })
            )
          );
        in
          {
            "Mod+O".action = show-hotkey-overlay;
            "Mod+Q".action.spawn = "${lib.getExe pkgs.ghostty}";
            "Mod+R".action.spawn = "${lib.getExe pkgs.fuzzel}";
            "Mod+C".action.close-window = [];

            "Mod+Comma".action = consume-window-into-column;
            "Mod+Period".action = expel-window-from-column;

            "Mod+T".action = switch-preset-column-width;
            "Mod+F".action = maximize-column;
            "Mod+Shift+F".action = fullscreen-window;
            "Mod+D".action = center-column;
            "Mod+B".action = toggle-window-floating;

            "Mod+Minus".action = set-column-width "-10%";
            "Mod+Equal".action = set-column-width "+10%";
            "Mod+Shift+Minus".action = set-window-height "-10%";
            "Mod+Shift+Equal".action = set-window-height "+10%";

            "Mod+Shift+Escape".action = toggle-keyboard-shortcuts-inhibit;
            "Mod+Shift+E".action = quit;
            "Mod+Shift+P".action = power-off-monitors;
            "Mod+Shift+L".action.spawn = "${lib.getExe pkgs.powermenu}";

            "Mod+Shift+Ctrl+T".action = toggle-debug-tint;

            "Mod+Shift+WheelScrollDown".action = focus-workspace-down;
            "Mod+Shift+WheelScrollUp".action = focus-workspace-up;
            "Mod+WheelScrollDown".action = focus-column-right;
            "Mod+WheelScrollUp".action = focus-column-left;

            "Mod+Shift+S".action.screenshot = {};
            "Mod+S".action.screenshot-window = {};

            "XF86MonBrightnessDown".action.spawn = [(lib.getExe pkgs.brightnessctl) "set" "5%-"];
            "XF86MonBrightnessUp".action.spawn = [(lib.getExe pkgs.brightnessctl) "set" "+5%"];
            "XF86AudioLowerVolume".action.spawn = [(lib.getExe' pkgs.wireplumber "wpctl") "set-volume" "@DEFAULT_AUDIO_SINK@" "2%-"];
            "XF86AudioRaiseVolume".action.spawn = [(lib.getExe' pkgs.wireplumber "wpctl") "set-volume" "@DEFAULT_AUDIO_SINK@" "2%+"];
          }
          // windowMoves;
      };
    };
  };
}
