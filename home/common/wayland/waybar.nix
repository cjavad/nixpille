{ pkgs, config, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      main = {
        layer = "top";
        position = "top";
        height = 28;
        spacing = 0;
        margin-top = 4;
        margin-left = 8;
        margin-right = 8;
        margin-bottom = 0;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/submap"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "custom/nightlight"
          "custom/github"
          "idle_inhibitor"
          "pulseaudio"
          "backlight"
          "bluetooth"
          "network"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "0";
            special = "";
            urgent = "";
            default = "";
          };
          on-click = "activate";
        };

        "hyprland/submap" = {
          format = "";
          tooltip = true;
          tooltip-format = "Submap: {}";
        };

        "custom/nightlight" = {
          format = "{}";
          interval = 30;
          exec = ''pgrep -x sunsetr > /dev/null && echo "" || echo ""'';
          tooltip = true;
          tooltip-format = "Blue light filter (sunsetr)";
          on-click = "sunsetr toggle";
        };

        "custom/github" = {
          interval = 300;
          tooltip = true;
          tooltip-format = "GitHub notifications";
          return-type = "json";
          format = " {}";
          exec = "gh api '/notifications' -q '{ text: length }' | cat -";
          exec-if = "[ -x \"$(command -v gh)\" ] && gh auth status 2>&1 | grep -q -m 1 'Logged in' && test $(gh api '/notifications' -q 'length') -ne 0";
          on-click = "xdg-open https://github.com/notifications";
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%a %d %b}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            weeks-pos = "right";
            format = {
              months = "<span color='#cdd6f4'><b>{}</b></span>";
              days = "<span color='#cdd6f4'>{}</span>";
              weeks = "<span color='#89b4fa'>W{}</span>";
              weekdays = "<span color='#fab387'>{}</span>";
              today = "<span color='#f38ba8'><b><u>{}</u></b></span>";
            };
          };
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
          tooltip = true;
          tooltip-format-activated = "Idle inhibitor: ON";
          tooltip-format-deactivated = "Idle inhibitor: OFF";
        };

        pulseaudio = {
          format = "{icon}";
          format-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
          tooltip = true;
          tooltip-format = "{volume}% - {desc}";
          on-click = "pavucontrol";
          on-click-right = "swayosd-client --output-volume mute-toggle";
          on-scroll-up = "swayosd-client --output-volume raise";
          on-scroll-down = "swayosd-client --output-volume lower";
        };

        backlight = {
          format = "{icon}";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
          tooltip = true;
          tooltip-format = "Brightness: {percent}%";
          on-scroll-up = "swayosd-client --brightness raise";
          on-scroll-down = "swayosd-client --brightness lower";
        };

        bluetooth = {
          format = "";
          format-connected = "";
          format-disabled = "";
          format-off = "";
          tooltip = true;
          tooltip-format = "{controller_alias}: {status}";
          tooltip-format-connected = "{controller_alias}\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
          tooltip-format-enumerate-connected-battery = "{device_alias} {device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        network = {
          format-wifi = "";
          format-ethernet = "";
          format-linked = "";
          format-disconnected = "";
          tooltip = true;
          tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}\n {bandwidthDownBytes}  {bandwidthUpBytes}";
          tooltip-format-ethernet = "{ifname}\n{ipaddr}/{cidr}\n {bandwidthDownBytes}  {bandwidthUpBytes}";
          tooltip-format-disconnected = "Disconnected";
          on-click = "nm-connection-editor";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}";
          format-charging = "";
          format-plugged = "";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          tooltip = true;
          tooltip-format = "{capacity}% - {timeTo}\n{power}W";
        };

        tray = {
          icon-size = 14;
          spacing = 6;
        };
      };
    };

    # OLED-optimized CSS (true black backgrounds)
    style = ''
      /* OLED-optimized: True black backgrounds */
      window#waybar {
        background-color: transparent;
      }

      window#waybar > box {
        background-color: rgba(0, 0, 0, 0.95);
        border-radius: 8px;
        border: 1px solid rgba(30, 30, 46, 0.3);
        padding: 0 6px;
      }

      /* All modules: transparent background */
      #workspaces,
      #submap,
      #custom-nightlight,
      #custom-github,
      #clock,
      #idle_inhibitor,
      #pulseaudio,
      #backlight,
      #bluetooth,
      #network,
      #battery,
      #tray {
        padding: 0 6px;
        margin: 3px 1px;
        background-color: transparent;
        border-radius: 4px;
        transition: all 0.15s ease;
      }

      /* Hover: subtle highlight */
      #custom-nightlight:hover,
      #custom-github:hover,
      #clock:hover,
      #idle_inhibitor:hover,
      #pulseaudio:hover,
      #backlight:hover,
      #bluetooth:hover,
      #network:hover,
      #battery:hover {
        background-color: rgba(49, 50, 68, 0.4);
      }

      /* Workspaces */
      #workspaces { padding: 0 2px; }

      #workspaces button {
        padding: 0 5px;
        color: rgba(205, 214, 244, 0.6);
        border-radius: 4px;
        margin: 2px 1px;
        background-color: transparent;
      }

      #workspaces button:hover {
        background-color: rgba(49, 50, 68, 0.4);
        color: @base05;
      }

      #workspaces button.active {
        background-color: transparent;
        color: #cdd6f4;
        font-weight: bold;
      }

      #workspaces button.urgent {
        background-color: rgba(243, 139, 168, 0.8);
        color: #000000;
      }

      #workspaces button.special {
        background-color: rgba(203, 166, 247, 0.8);
        color: #000000;
      }

      /* Submap */
      #submap {
        background-color: rgba(250, 179, 135, 0.9);
        color: #000000;
        font-weight: bold;
      }

      /* Nightlight */
      #custom-nightlight { color: @base0A; }

      /* GitHub */
      #custom-github { color: @base05; }

      /* Clock */
      #clock { color: @base05; font-weight: bold; }

      /* Status icons: dimmed by default */
      #idle_inhibitor,
      #pulseaudio,
      #backlight,
      #bluetooth,
      #network,
      #battery {
        color: rgba(205, 214, 244, 0.7);
      }

      #idle_inhibitor.activated { color: @base0A; }
      #pulseaudio.muted { color: rgba(205, 214, 244, 0.3); }
      #backlight { color: @base0A; }
      #bluetooth { color: @base0D; }
      #bluetooth.disabled, #bluetooth.off { color: rgba(205, 214, 244, 0.3); }
      #bluetooth.connected { color: @base0C; }
      #network { color: @base0C; }
      #network.disconnected { color: rgba(205, 214, 244, 0.3); }

      /* Battery */
      #battery { color: @base0B; }
      #battery.charging { color: @base0B; }
      #battery.warning:not(.charging) { color: @base0A; }
      #battery.critical:not(.charging) {
        color: @base08;
        animation: blink 0.5s linear infinite alternate;
      }

      @keyframes blink { to { color: @base09; } }

      /* Tray */
      #tray { padding: 0 4px; }
      #tray > .passive { -gtk-icon-effect: dim; }
      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: rgba(243, 139, 168, 0.8);
        border-radius: 4px;
      }

      /* Tooltips */
      tooltip {
        background-color: rgba(0, 0, 0, 0.95);
        border: 1px solid rgba(49, 50, 68, 0.5);
        border-radius: 6px;
      }

      tooltip label { color: @base05; }
    '';
  };
}
