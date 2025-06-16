{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (osConfig.desktop.enable && osConfig.desktop.niri) {
    home.packages = [pkgs.nautilus]; # xdg-desktop-portal-gnome wants it
    programs.niri = {
      package = pkgs.niri-unstable;
      settings = {
        environment = {
          NIXOS_OZONE_WL = "1";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          QT_QPA_PLATFORMTHEME = "qt5ct";
          QT_QPA_PLATFORM = "wayland";
          DISPLAY = ":0";
        };

        screenshot-path = null;
        prefer-no-csd = true;

        input = {
          focus-follows-mouse = {
            enable = true;
            max-scroll-amount = "80%";
          };
          keyboard = {
            repeat-delay = 300;
            repeat-rate = 5;
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
          default-column-width = {
            proportion = 0.5;
          };
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
          {
            matches = [
              {
                title = "Picture-in-Picture";
              }
            ];
            open-floating = true;
            default-floating-position = {
              x = 16;
              y = 16;
              relative-to = "bottom-right";
            };
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
          toAction = act: dir: (lib.mapAttrs' (
              argName: argValue:
                lib.nameValuePair "${argName}+${dir.name}" {
                  action = {
                    "${argValue}-${dir.value}" = [];
                  };
                }
            )
            act);
          windowMoves = lib.mergeAttrsList (
            (
              map
              (toAction {
                "Mod" = "focus";
                "Mod+Ctrl" = "move";
              })
              (
                lib.attrsToList {
                  "Up" = "window-up";
                  "k" = "window-up";
                  "Down" = "window-down";
                  "j" = "window-down";
                  "Left" = "column-left";
                  "h" = "column-left";
                  "Right" = "column-right";
                  "l" = "column-right";
                  "I" = "workspace-down";
                  "U" = "workspace-up";
                }
              )
            )
            ++ (
              map
              (toAction {
                "Mod+Shift" = "focus";
                "Mod+Ctrl+Shift" = "move-window-to";
              })
              (
                lib.attrsToList {
                  "Up" = "monitor-up";
                  "K" = "monitor-up";
                  "Down" = "monitor-down";
                  "J" = "monitor-down";
                  "Left" = "monitor-left";
                  "H" = "monitor-left";
                  "Right" = "monitor-right";
                  "L" = "monitor-right";
                  "I" = "workspace-down";
                  "U" = "workspace-up";
                }
              )
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
            "Mod+Shift+Ctrl+T".action = toggle-debug-tint;

            "Mod+Shift+WheelScrollDown".action = focus-workspace-down;
            "Mod+Shift+WheelScrollUp".action = focus-workspace-up;
            "Mod+WheelScrollDown".action = focus-column-right;
            "Mod+WheelScrollUp".action = focus-column-left;

            "Mod+Shift+S".action.screenshot = {};
            "Mod+S".action.screenshot-window = {};

            "XF86MonBrightnessDown".action.spawn = [
              (lib.getExe pkgs.brightnessctl)
              "set"
              "5%-"
            ];
            "XF86MonBrightnessUp".action.spawn = [
              (lib.getExe pkgs.brightnessctl)
              "set"
              "+5%"
            ];
            "XF86AudioLowerVolume".action.spawn = [
              (lib.getExe' pkgs.wireplumber "wpctl")
              "set-volume"
              "@DEFAULT_AUDIO_SINK@"
              "2%-"
            ];
            "XF86AudioRaiseVolume".action.spawn = [
              (lib.getExe' pkgs.wireplumber "wpctl")
              "set-volume"
              "@DEFAULT_AUDIO_SINK@"
              "2%+"
            ];
          }
          // windowMoves;

        animations = let
          vm = {
            spring = {
              damping-ratio = 0.75;
              stiffness = 200;
              epsilon = 0.0001;
            };
          };
        in {
          horizontal-view-movement = vm;
          workspace-switch = vm;
          window-resize = vm;

          window-open = {
            easing = {
              duration-ms = 200;
              curve = "linear";
            };
          };
          shaders.window-open = ''
            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                vec3 coords_tex = niri_geo_to_tex * coords_geo;
                vec4 color = texture2D(niri_tex, coords_tex.st);

                vec2 coords = (coords_geo.xy - vec2(0.5, 0.5)) * size_geo.xy * 2.0;
                coords = coords / length(size_geo.xy);
                float p = niri_clamped_progress;
                if (p * p <= dot(coords, coords))
                    color = vec4(0.0);

                return color;
            }
          '';
        };
      };
    };
  };
}
