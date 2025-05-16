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
      settings.mainBar = let
        hctl = lib.meta.getExe pkgs.hyprland;
      in {
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
        modules-center = ["hyprland/workspaces"];
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
          on-scroll-up = "${hctl} dispatch workspace e+1";
          on-scroll-down = "${hctl} dispatch workspace e-1";
        };

        "custom/launcher" = {
          interval = "once";
          format = "";
          on-click = "${hctl} keyword exec '$menu'";
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
          format = "{icon}  {percent}%";
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
          format = "{icon}   {volume}%";
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
          format = "{icon}  {capacity}%";
          format-warning = "{icon}  {capacity}%";
          format-critical = "{icon}  {capacity}%";
          format-charging = "  {capacity}%";
          format-plugged = "  {capacity}%";
          format-alt = "{icon}  {time}";
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
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format = "󰥔  {:%H:%M:%S}";
          interval = 5;
        };

        "custom/powermenu" = {
          format = "";
          on-click = "${lib.getExe pkgs.powermenu}";
          tooltip = false;
        };
      };

      style = ''
        @define-color base   #1e1e2e;
        @define-color mantle #181825;
        @define-color crust  #11111b;

        @define-color text     #cdd6f4;
        @define-color subtext0 #a6adc8;
        @define-color subtext1 #bac2de;

        @define-color surface0 #313244;
        @define-color surface1 #45475a;
        @define-color surface2 #585b70;

        @define-color overlay0 #6c7086;
        @define-color overlay1 #7f849c;
        @define-color overlay2 #9399b2;

        @define-color blue      #89b4fa;
        @define-color lavender  #b4befe;
        @define-color sapphire  #74c7ec;
        @define-color sky       #89dceb;
        @define-color teal      #94e2d5;
        @define-color green     #a6e3a1;
        @define-color yellow    #f9e2af;
        @define-color peach     #fab387;
        @define-color maroon    #eba0ac;
        @define-color red       #f38ba8;
        @define-color mauve     #cba6f7;
        @define-color pink      #f5c2e7;
        @define-color flamingo  #f2cdcd;
        @define-color rosewater #f5e0dc;

        /* margin: top right bottom left */
        /* Spacing outside the element */

        /* padding: top right bottom left */
        /* Spacing inside the element */

        * {
          font-size: 16px;
        }

        window#waybar {
          background-color: @crust;
          color: @text;
          transition-property: background-color;
          transition-duration: 0.5s;
          border-radius: 0px;
          transition-duration: 0.5s;
          margin: 16px 16px;
        }

        window#waybar.hidden {
          opacity: 0.2;
        }

        #workspaces button {
          color: @text;
          background: @background3;
          border-radius: 8px;
          padding: 0px 10px 0px 10px;
          margin: 7px 5px 10px 5px;
          border: 1px solid @subtext1;
        }

        #workspaces button:hover {
          background: @surface0;
          color: @text;
        }

        #workspaces button.active {
          color: @crust;
          background: @overlay2;
          border: none;
        }

        #custom-launcher,
        #clock,
        #battery,
        #cpu,
        #temperature,
        #backlight,
        #network,
        #pulseaudio,
        #custom-dunst,
        #custom-powermenu {
          padding: 0px 16px;
          margin: 7px 0px 10px 0px;
          border-radius: 8px;
          color: @crust;
        }

        #window,
        #custom-launcher {
          padding: 0px 25px 0px 20px;
          margin: 7px 0px 10px 20px;
          background-color: @mauve;
        }

        #cpu {
          background-color: @lavender;
        }

        #temperature {
          background-color: @blue;
        }

        #backlight {
          background-color: @sapphire;
        }

        #custom-dunst {
          padding: 0px 20px 0px 13px;
          background-color: @sky;
        }

        #pulseaudio {
          padding: 0px 20px 0px 17px;
          background-color: @teal;
        }

        #network {
          padding: 0px 15px 0px 20px;
          background-color: @green;
        }

        #battery {
          background-color: @yellow;
        }

        #clock {
          background-color: @peach;
        }

        #custom-powermenu {
          padding: 0px 25px 0px 20px;
          margin: 7px 20px 10px 0px;
          background-color: @maroon;
        }

        @keyframes blink {
          to {
            background-color: rgba(30, 34, 42, 0.5);
            color: #abb2bf;
          }
        }

        #battery.critical:not(.charging) {
          color: #f53c3c;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }

        label:focus {
          background-color: #000000;
        }
      '';
    };
  };
}
