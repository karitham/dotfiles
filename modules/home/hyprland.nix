{
  osConfig,
  lib,
  pkgs,
  ...
}: let
  powermenu = pkgs.writeShellScriptBin "powermenu" ''
    declare -rA power_menu=(
        ["  Lock"]="${pkgs.systemd}/bin/loginctl lock-sessions"
        ["  Sleep"]='systemctl suspend'
        ["  Shut down"]="systemctl poweroff"
        ["  Reboot"]="systemctl reboot"
    )

    set -e -x
    selected_option=$(printf '%s\n' "''${!power_menu[@]}" | rofi -dmenu)

    if [[ -n $selected_option ]] && [[ -v power_menu[$selected_option] ]]; then
        eval "''${power_menu[$selected_option]}"
    fi
  '';
in {
  config = lib.mkIf osConfig.desktop.enable {
    home.packages = [powermenu];
    services.hyprpaper = {
      enable = true;
      settings = {
        preload = ["${osConfig.desktop.wallpaper}"];
        wallpaper = [", ${osConfig.desktop.wallpaper}"];
      };
    };
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      settings = {
        exec-once = ["dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"];

        monitor = [", preferred, auto, 1"];

        env = [
          "XCURSOR_SIZE,24"
          "QT_QPA_PLATFORMTHEME,qt5ct" # change to qt6ct if you have that
        ];

        "$powermenu" = "${lib.meta.getExe powermenu}";
        "$menu" = "${lib.meta.getExe pkgs.rofi-wayland-unwrapped} -show drun";

        input = {
          kb_layout = "us";
          kb_variant = "intl";
          follow_mouse = "1";

          touchpad = {
            natural_scroll = "no";
          };

          accel_profile = "flat";
          sensitivity = "0";
        };

        general = {
          gaps_in = "0";
          gaps_out = "0";
          border_size = "0";
          layout = "dwindle";
          allow_tearing = "false";
        };

        decoration = {
          blur = {
            enabled = "true";
            size = "3";
            passes = "1";
          };
        };

        animations = {
          enabled = "yes";
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        dwindle = {
          pseudotile = "yes";
          preserve_split = "yes";
        };

        master = {
          new_status = "master";
        };

        gestures = {
          workspace_swipe = "off";
        };

        windowrulev2 = [
          "float,class:^(org.pulseaudio.pavucontrol)$"
          "opacity 0.0 override,class:^(xwaylandvideobridge)$"
          "noanim,class:^(xwaylandvideobridge)$"
          "noinitialfocus,class:^(xwaylandvideobridge)$"
          "noblur,class:^(xwaylandvideobridge)$"
        ];

        "$mainMod" = "SUPER";

        bind = let
          generateBindings = keyBind: workspacePrefix: i: "${keyBind}, ${toString i}, ${workspacePrefix}, ${toString i}";
          screenshot = "${lib.meta.getExe pkgs.grim} -g \"$(${lib.meta.getExe pkgs.slurp} -d)\" -";
        in
          [
            # Software
            "$mainMod, Q, exec, ghostty"
            "$mainMod SHIFT, Q, exec, [float] ghostty --background-opacity=0.85"
            "$mainMod, R, exec, $menu"
            "$mainMod SHIFT, L, exec, $powermenu"

            # Generic
            "$mainMod, C, killactive"
            "$mainMod, M, exit"
            "$mainMod, V, togglefloating"
            "$mainMod, P, pseudo"
            "$mainMod, B, togglesplit"

            # Focus
            "$mainMod, h, movefocus, l"
            "$mainMod, l, movefocus, r"
            "$mainMod, k, movefocus, u"
            "$mainMod, j, movefocus, d"

            # Screenshot
            "$mainMod, S, exec, ${screenshot} | wl-copy"
            "$mainMod SHIFT, S, exec, ${screenshot} | ${lib.meta.getExe pkgs.swappy} -f - -o - | wl-copy"

            # Scroll through worskpaces
            "$mainMod, mouse_down, workspace, e+1"
            "$mainMod, mouse_up, workspace, e-1"

            # Move workspace to another screen
            "$mainMod CTRL, h, movecurrentworkspacetomonitor, l"
            "$mainMod CTRL, l, movecurrentworkspacetomonitor, r"
            "$mainMod CTRL, k, movecurrentworkspacetomonitor, u"
            "$mainMod CTRL, j, movecurrentworkspacetomonitor, d"
          ]
          ++ map (i: generateBindings "$mainMod" "workspace" i) (pkgs.lib.range 1 9)
          ++ map (i: generateBindings "$mainMod SHIFT" "movetoworkspace" i) (pkgs.lib.range 1 9);

        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        bindle = [
          ",XF86MonBrightnessUp,   exec, ${lib.meta.getExe pkgs.brightnessctl} set +5%"
          ",XF86MonBrightnessDown, exec, ${lib.meta.getExe pkgs.brightnessctl} set  5%-"
          ",XF86KbdBrightnessUp,   exec, ${lib.meta.getExe pkgs.brightnessctl} -d asus::kbd_backlight set +1"
          ",XF86KbdBrightnessDown, exec, ${lib.meta.getExe pkgs.brightnessctl} -d asus::kbd_backlight set  1-"
        ];

        bindl = [
          ",XF86AudioPlay,    exec, ${lib.meta.getExe pkgs.playerctl} play-pause"
          ",XF86AudioStop,    exec, ${lib.meta.getExe pkgs.playerctl} pause"
          ",XF86AudioPause,   exec, ${lib.meta.getExe pkgs.playerctl} pause"
          ",XF86AudioPrev,    exec, ${lib.meta.getExe pkgs.playerctl} previous"
          ",XF86AudioNext,    exec, ${lib.meta.getExe pkgs.playerctl} next"
        ];
      };
    };
  };
}
