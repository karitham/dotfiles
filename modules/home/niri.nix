{
  config,
  osConfig,
  lib,
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.niri.homeModules.niri];

  config = lib.mkIf (osConfig.desktop.enable && osConfig.desktop.niri) {
    programs.niri = {
      settings = {
        environment = {
          NIXOS_OZONE_WL = "1";
        };

        input = {
          keyboard.xkb = {
            layout = "us";
            variant = "intl";
          };

          mouse.accel-speed = 1.0;
          touchpad = {
            tap = true;
            dwt = true;
            natural-scroll = true;
            click-method = "clickfinger";
          };
        };

        spawn-at-startup = let
          # https://github.com/sodiboo/system/blob/main/niri.mod.nix#L273
          get-wayland-display = "systemctl --user show-environment | awk -F 'WAYLAND_DISPLAY=' '{print $2}' | awk NF";
          wrapper = name: op:
            pkgs.writeScript "${name}" ''
              if [ "$(${get-wayland-display})" ${op} "$WAYLAND_DISPLAY" ]; then
                exec "$@"
              fi
            '';

          only-without-session = wrapper "only-without-session" "!=";
        in [
          {
            command = [
              "${only-without-session}"
              "${lib.getExe pkgs.waybar}"
            ];
          }
        ];

        binds = with config.lib.niri.actions; let
          # programs.niri.settings.binds."Mod+Q".action.close-window = []
          toAction = dir: (lib.mapAttrs' (argName: argValue: lib.nameValuePair "${argName}+${dir.name}" {action = {"${argValue}-${dir.value}" = [];};}) {
            "Mod" = "focus";
            "Mod+Ctrl" = "move";
            # "Mod+Shift" = "focus-monitor";
            # "Mod+Ctrl+Shift" = "move-window-to-monitor";
          });

          windowMoves = lib.mergeAttrsList (map toAction (lib.attrsToList {
            "Up" = "window-up";
            "Down" = "window-down";
            "Left" = "column-left";
            "Right" = "column-right";
          }));
        in
          {
            "Mod+O".action = show-hotkey-overlay;
            "Mod+Q".action.spawn = "${lib.meta.getExe pkgs.ghostty}";
            "Mod+R".action.spawn = "${lib.meta.getExe pkgs.fuzzel}";
            "Mod+C".action.close-window = [];

            "Mod+Comma".action = consume-window-into-column;
            "Mod+Period".action = expel-window-from-column;

            "Mod+T".action = switch-preset-column-width;
            "Mod+F".action = maximize-column;
            "Mod+Shift+F".action = fullscreen-window;
            "Mod+D".action = center-column;

            "Mod+Minus".action = set-column-width "-10%";
            "Mod+Plus".action = set-column-width "+10%";
            "Mod+Shift+Minus".action = set-window-height "-10%";
            "Mod+Shift+Plus".action = set-window-height "+10%";

            "Mod+Shift+Escape".action = toggle-keyboard-shortcuts-inhibit;
            "Mod+Shift+E".action = quit;
            "Mod+Shift+P".action = power-off-monitors;

            "Mod+Shift+Ctrl+T".action = toggle-debug-tint;
          }
          // windowMoves;
      };
    };
  };
}
