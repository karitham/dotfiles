{
  osConfig,
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
          "cpu"
          "temperature"
          "backlight"
        ];

        modules-center = lib.optional osConfig.desktop.niri "niri/workspaces";

        modules-right = [
          "pulseaudio"
          "network"
          "battery"
          "clock"
        ];

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
          format = " {usage}%";
          max-length = 10;
        };

        temperature = {
          hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
          input-filename = "tem1_input";
          format = " {temperatureC}°C";
          format-critical = " {temperatureC}°C";
          on-click = "psensor";
          critical-threshold = 80;
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
          format-wifi = " {signalStrength}%";
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
          format-full = " {capacity}%";
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

      style = ''
        * {
          font-family: ${osConfig.fonts.mono}, Noto Sans CJK SC;
          font-weight: bold;
          font-size: 14px;
        }

        window#waybar {
          color: @text;
          background: transparent;
          padding: 0 0.375em;
        }

        #waybar > box {
          background: @base;
          opacity: 0.95;
          border-radius: 1.25em;
          margin: 0.5em 0.5em 0 0.5em;
          padding: 0 0.5em;
        }

        #waybar > box > * {
          padding: 0 0.625em;
          margin: 0 0.1875em;
          background: transparent;
          transition: color 120ms ease, background 120ms ease;
        }

        #waybar > box > * label { padding-top: 0.0625em; }
        #clock { margin-right: 0; }

        #workspaces { border-radius: 0; }

        #workspaces button {
          color: @subtext0;
          padding: 0 0.625em;
          border-bottom: 0.125em solid transparent;
          transition: border-color 120ms ease, color 120ms ease;
        }

        #workspaces button.focused,
        #workspaces button.active {
          color: @text;
          border-bottom-color: @mauve;
        }

        #workspaces button.urgent {
          color: @red;
          border-bottom-color: @red;
        }

        #workspaces button.empty {
          font-size: 0;
          min-width: 0;
          min-height: 0;
          opacity: 0;
        }

        #battery.charging,
        #battery.full { color: @green; }
        #battery.warning { color: @yellow; }
        #battery.critical,
        #network.disconnected,
        #temperature.critical { color: @red; }
        #network.ethernet { color: @teal; }
        #network.wifi { color: @sky; }
        #pulseaudio.muted,
        .muted { color: @overlay1; }

        tooltip {
          background: @mantle;
          color: @text;
          border: 0.0625em solid @surface1;
          border-radius: 0.25em;
          padding: 0.375em 0.625em;
        }
      '';
    };
  };
}
