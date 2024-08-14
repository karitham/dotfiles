{pkgs, ...}: {
  wayland.windowManager.hyprland = let
    getExe = name: "${pkgs."${name}"}/bin/${name}";
  in {
    enable = true;
    systemd.enable = true;
    settings = {
      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      ];
      monitor = ",preferred,auto,auto";

      env = [
        "XCURSOR_SIZE,24"
        "QT_QPA_PLATFORMTHEME,qt5ct" # change to qt6ct if you have that
      ];

      "$powermenu" = "${./dotfiles/powermenu.sh}";
      "$menu" = "${pkgs.rofi-wayland-unwrapped}/bin/rofi -show drun";

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
        gaps_in = "5";
        gaps_out = "20";
        border_size = "2";
        layout = "dwindle";
        allow_tearing = "false";
      };

      decoration = {
        rounding = "10";

        blur = {
          enabled = "true";
          size = "3";
          passes = "1";
        };

        drop_shadow = "yes";
        shadow_range = "4";
        shadow_render_power = "3";
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

      misc = {
        force_default_wallpaper = "-1";
      };

      windowrulev2 = [
        # Make pavucontrol float
        "float,class:^(pavucontrol)$"
        "opacity 0.0 override,class:^(xwaylandvideobridge)$"
        "noanim,class:^(xwaylandvideobridge)$"
        "noinitialfocus,class:^(xwaylandvideobridge)$"
        "noblur,class:^(xwaylandvideobridge)$"
      ];

      "$mainMod" = "SUPER";

      bind = let
        generateBindings = keyBind: workspacePrefix: i: "${keyBind}, ${toString i}, ${workspacePrefix}, ${toString i}";
        screenshot = "${getExe "grim"} -g \"$(${getExe "slurp"} -d)\" -";
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
          "$mainMod, S, togglesplit"

          # Focus
          "$mainMod, h, movefocus, l"
          "$mainMod, l, movefocus, r"
          "$mainMod, k, movefocus, u"
          "$mainMod, j, movefocus, d"

          # Screenshot
          "$mainMod, S, exec, ${screenshot} | wl-copy"
          "$mainMod SHIFT, S, exec, ${screenshot} | ${getExe "swappy"} -f - -o - | wl-copy"

          # Scroll through worskpaces
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"

          # Move workspace to another screen
          "$mainMod CTRL, h, movecurrentworkspacetomonitor, l"
          "$mainMod CTRL, l, movecurrentworkspacetomonitor, r"
          "$mainMod CTRL, k, movecurrentworkspacetomonitor, u"
          "$mainMod CTRL, j, movecurrentworkspacetomonitor, d"
        ]
        ++ map
        (i: generateBindings "$mainMod" "workspace" i)
        (pkgs.lib.range 1 9)
        ++ map
        (i: generateBindings "$mainMod SHIFT" "movetoworkspace" i)
        (pkgs.lib.range 1 9);

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bindle = [
        ",XF86MonBrightnessUp,   exec, ${getExe "brightnessctl"} set +5%"
        ",XF86MonBrightnessDown, exec, ${getExe "brightnessctl"} set  5%-"
        ",XF86KbdBrightnessUp,   exec, ${getExe "brightnessctl"} -d asus::kbd_backlight set +1"
        ",XF86KbdBrightnessDown, exec, ${getExe "brightnessctl"} -d asus::kbd_backlight set  1-"
      ];

      bindl = [
        ",XF86AudioPlay,    exec, ${getExe "playerctl"} play-pause"
        ",XF86AudioStop,    exec, ${getExe "playerctl"} pause"
        ",XF86AudioPause,   exec, ${getExe "playerctl"} pause"
        ",XF86AudioPrev,    exec, ${getExe "playerctl"} previous"
        ",XF86AudioNext,    exec, ${getExe "playerctl"} next"
      ];
    };
  };
}
