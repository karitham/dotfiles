{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf osConfig.desktop.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings.mainBar = {
        font = osConfig.fonts.mono;
        height = 40;
        layer = "top";
        position = "top";
        output = "eDP-1";
        spacing = 7;
        modules-left = [
          "custom/launcher"
          "cpu"
          "temperature"
          "backlight"
        ];

        modules-center =
          lib.optional osConfig.desktop.hyprland "hyprland/workspaces"
          ++ lib.optional osConfig.desktop.niri "niri/workspaces";

        modules-right = [
          "pulseaudio"
          "network"
          "battery"
          "clock"
          "custom/powermenu"
        ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          on-click = "activate";
          on-scroll-up = "${lib.meta.getExe pkgs.hyprland} dispatch workspace e+1";
          on-scroll-down = "${lib.meta.getExe pkgs.hyprland} dispatch workspace e-1";
        };

        "niri/workspaces" = {
          format = "{value}";
          all-outputs = true;
          format-icons = {
            active = "";
            default = "";
          };
        };

        "custom/launcher" = {
          interval = "once";
          format = "";
          tooltip = false;
        };

        cpu = {
          interval = 10;
          format = "  {usage}%";
          max-length = 10;
        };

        temperature = {
          hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
          input-filename = "tem1_input";
          format = " {temperatureC}°C";
          on-click = "psensor";
        };

        backlight = let
          bctl = lib.meta.getExe pkgs.brightnessctl;
        in {
          device = "eDP-1";
          max-length = "4";
          format = "{icon} {percent}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
          on-scroll-up = pkgs.writeShellScript "brightness.sh" ''
            MIN_BRIGHTNESS=5
            current_brightness=$(${bctl} g)
            max_brightness=$(${bctl} m)
            min_brightness_raw=$((max_brightness * MIN_BRIGHTNESS / 100))
            scaling_factor=30
            decrement=$((max_brightness / scaling_factor))
            new_brightness_raw=$((current_brightness - decrement))
            if [ "$new_brightness_raw" -lt "$min_brightness_raw" ]; then
              new_brightness_raw=$min_brightness_raw
            fi
            ${bctl} set "$new_brightness_raw"
          '';
          on-scroll-down = "${bctl} set +5%";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "{icon}  {volume}%  {format_source}";
          format-bluetooth-muted = "󰂲  {icon}  {format_source}";
          format-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = lib.meta.getExe pkgs.pavucontrol;
        };

        network = {
          format-wifi = "  {signalStrength}%";
          format-ethernet = "󰈀 ";
          format-disconnected = "󰖪 ";
        };

        battery = {
          bat = "CMB0";
          adapter = "ADP0";
          interval = 30;
          states = {
            warning = 30;
            critical = 15;
          };
          max-length = 20;
          format = "{icon} {capacity}%";
          format-warning = "{icon} {capacity}%";
          format-critical = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{icon} {time}";
          format-full = "  {capacity}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
        };

        clock = {
          format = "󰥔 {:%F %H:%M:%S}";
          interval = 1;
        };
      };

      style = let
        background = "@base";
        text = "@text";
        bg-active = "@surface0";
        accent = "@${config.catppuccin.accent}";
        warning = "@yellow";
        critical = "@red";
        active = "@green";
      in ''
        * {
          font-family: ${osConfig.fonts.mono}, Noto Sans CJK SC;
          font-weight: bold;
          font-size: 17px;
        }
        window#waybar {
          color: ${text};
          opacity: 0.95;
          background-color: ${background};
          padding: 0 10px;
        }
        #custom-launcher {
          color: ${text};
          background-color: ${background};
          border-radius: 10px;
          padding-left: 15px;
          padding-right: 18px;
        }
        #workspaces {
          color: ${text};
          background-color: ${background};
          border-radius: 0;
        }
        #workspaces button {
          color: ${text};
          padding: 0 10px;
          border-radius: 0;
        }
        #workspaces button.focused,
        #workspaces button.active {
          background-color: ${bg-active};
          border-bottom: 4px solid ${accent};
        }
        #workspaces button.empty {
          font-size: 0;
          min-width: 0;
          min-height: 0;
          margin: 0;
          padding: 0;
          border: 0;
          opacity: 0;
          box-shadow: none;
          background-color: transparent;
        }
        #cpu,
        #pulseaudio,
        #network,
        #battery {
          color: ${text};
        }
        #clock {
          color: ${text};
          margin-right: 15px;
        }
        #battery.warning {
          color: ${warning};
        }
        #battery.critical {
          color: ${critical};
        }
        #battery.charging {
          color: ${active};
        }
      '';
    };
  };
}
