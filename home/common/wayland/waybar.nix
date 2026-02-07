{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.custom.waybar;
in
{
  options.custom.waybar = {
    showBattery = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to show the battery module in waybar";
    };
  };

  config = {
    # Disable Stylix waybar styling - use custom OLED-optimized CSS
    stylix.targets.waybar.enable = false;
  }
  // (
    let
      clockStateFile = "/tmp/waybar-clock-mode";
      submapIndicatorScript = pkgs.writeScript "submap-indicator" ''
        #!/usr/bin/env bash
        SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
        STATE_FILE="${clockStateFile}"

        get_clock_text() {
            if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "date" ]]; then
                date +"%a %d %b"
            else
                date +"%H:%M"
            fi
        }

        output_json() {
            local submap="$1"
            if [[ -z "$submap" ]]; then
                printf '{"text": "%s", "class": "clock", "tooltip": "%s"}\n' \
                    "$(get_clock_text)" "$(date +"%A, %d %B %Y - %H:%M")"
            elif [[ "$submap" == "screenshot" ]]; then
                printf '{"text": "󰩭 Area (P), 󰍹 Full (O), ⇧=clip", "class": "screenshot", "tooltip": "P: area screenshot\\nO: fullscreen\\n+Shift: clipboard only\\nEsc: exit"}\n'
            elif [[ "$submap" == "recording" ]]; then
                printf '{"text": "󰻃 Record (R), 󰍬 +Audio (⇧R)", "class": "recording", "tooltip": "R: record screen\\nShift+R: record with audio\\nEsc: exit"}\n'
            else
                printf '{"text": " %s", "class": "submap", "tooltip": "Submap: %s"}\n' "$submap" "$submap"
            fi
        }

        output_json ""
        ${pkgs.socat}/bin/socat -u "UNIX-CONNECT:$SOCKET" - 2>/dev/null | while read -r line; do
            [[ "$line" == submap\>\>* ]] && output_json "''${line#submap>>}"
        done
      '';
      toggleClockScript = pkgs.writeScript "toggle-clock-mode" ''
        #!/usr/bin/env bash
        STATE_FILE="${clockStateFile}"
        if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "date" ]]; then
            echo "time" > "$STATE_FILE"
        else
            echo "date" > "$STATE_FILE"
        fi
        pkill -SIGRTMIN+1 waybar
      '';
    in
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
            ];
            modules-center = [
              "custom/submap-indicator"
              "clock"
            ];
            modules-right = [
              "custom/nightlight"
              "custom/github"
              "idle_inhibitor"
              "pulseaudio"
              "backlight"
              "bluetooth"
              "network"
            ]
            ++ lib.optionals cfg.showBattery [ "battery" ]
            ++ [
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
                special = "󰎕";
                urgent = "󰀦";
                default = "󰝥";
              };
              on-click = "activate";
            };

            "custom/submap-indicator" = {
              exec = "${submapIndicatorScript}";
              return-type = "json";
              tooltip = true;
              signal = 1;
              on-click = "${toggleClockScript}";
            };

            clock = {
              format = "{:%H:%M}";
              format-alt = "{:%a %d %b}";
              tooltip-format = "<tt>{calendar}</tt>";
            };

            "custom/nightlight" = {
              format = "{}";
              interval = 30;
              exec = ''pgrep -x sunsetr > /dev/null && echo "󰖨" || echo "󰖨"'';
              tooltip = true;
              tooltip-format = "Blue light filter (sunsetr)";
              on-click = "sunsetr toggle";
            };

            "custom/github" = {
              interval = 300;
              tooltip = true;
              tooltip-format = "GitHub notifications";
              return-type = "json";
              format = "󰊤 {}";
              exec = "gh api '/notifications' -q '{ text: length }' | cat -";
              exec-if = "[ -x \"$(command -v gh)\" ] && gh auth status 2>&1 | grep -q -m 1 'Logged in' && test $(gh api '/notifications' -q 'length') -ne 0";
              on-click = "xdg-open https://github.com/notifications";
            };

            idle_inhibitor = {
              format = "{icon}";
              format-icons = {
                activated = "󰅶";
                deactivated = "󰾪";
              };
              tooltip = true;
              tooltip-format-activated = "Idle inhibitor: ON";
              tooltip-format-deactivated = "Idle inhibitor: OFF";
            };

            pulseaudio = {
              format = "{icon}";
              format-muted = "󰝟";
              format-icons = {
                headphone = "󰋋";
                hands-free = "󰋋";
                headset = "󰋋";
                phone = "󰏲";
                portable = "󰏲";
                car = "󰄋";
                default = [
                  "󰕿"
                  "󰖀"
                  "󰕾"
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
                "󰃞"
                "󰃝"
                "󰃟"
                "󰃠"
              ];
              tooltip = true;
              tooltip-format = "Brightness: {percent}%";
              on-scroll-up = "swayosd-client --brightness raise";
              on-scroll-down = "swayosd-client --brightness lower";
            };

            bluetooth = {
              format = "󰂯";
              format-connected = "󰂱";
              format-disabled = "󰂲";
              format-off = "󰂲";
              tooltip = true;
              tooltip-format = "{controller_alias}: {status}";
              tooltip-format-connected = "{controller_alias}\n{num_connections} connected\n\n{device_enumerate}";
              tooltip-format-enumerate-connected = "{device_alias}";
              tooltip-format-enumerate-connected-battery = "{device_alias} {device_battery_percentage}%";
              on-click = "blueman-manager";
            };

            network = {
              format-wifi = "󰖩";
              format-ethernet = "󰈀";
              format-linked = "󰈀";
              format-disconnected = "󰖪";
              tooltip = true;
              tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}\n↓ {bandwidthDownBytes} ↑ {bandwidthUpBytes}";
              tooltip-format-ethernet = "{ifname}\n{ipaddr}/{cidr}\n↓ {bandwidthDownBytes} ↑ {bandwidthUpBytes}";
              tooltip-format-disconnected = "Disconnected";
              on-click = "nm-connection-editor";
            };

            battery = {
              states = {
                warning = 30;
                critical = 15;
              };
              format = "{icon}";
              format-charging = "󰂄";
              format-plugged = "󰚥";
              format-icons = [
                "󰂎"
                "󰁺"
                "󰁻"
                "󰁼"
                "󰁽"
                "󰁾"
                "󰁿"
                "󰂀"
                "󰂁"
                "󰂂"
                "󰁹"
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
          * {
            font-family: monospace;
            font-size: 13px;
          }

          /* OLED-optimized: True black backgrounds */
          window#waybar {
            background-color: transparent;
          }

          window#waybar > box {
            background-color: #000000;
            border-radius: 8px;
            border: none;
            padding: 0 6px;
          }

          /* All modules: transparent background */
          #workspaces,
          #clock,
          #custom-submap-indicator,
          #custom-nightlight,
          #custom-github,
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
          #custom-submap-indicator:hover,
          #custom-nightlight:hover,
          #custom-github:hover,
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
            background-color: transparent;
            color: rgba(243, 139, 168, 1);
            font-weight: bold;
          }

          #workspaces button.special {
            background-color: rgba(203, 166, 247, 0.8);
            color: #000000;
          }

          /* Submap indicator - unified center module */
          #custom-submap-indicator {
            padding: 0 10px;
            transition: all 0.2s ease;
          }

          #custom-submap-indicator.clock {
            color: #cdd6f4;
            font-weight: bold;
          }

          #clock {
            color: #cdd6f4;
            font-weight: bold;
            background-color: transparent;
          }

          #custom-submap-indicator.screenshot {
            background-color: rgba(137, 180, 250, 0.9);
            color: #000000;
            font-weight: bold;
            padding: 0 15px;
          }

          #custom-submap-indicator.recording {
            background-color: rgba(243, 139, 168, 0.9);
            color: #000000;
            font-weight: bold;
            padding: 0 15px;
            animation: recording-pulse 1s ease-in-out infinite;
          }

          #custom-submap-indicator.submap {
            background-color: rgba(250, 179, 135, 0.9);
            color: #000000;
            font-weight: bold;
          }

          @keyframes recording-pulse { 50% { opacity: 0.7; } }

          /* Nightlight */
          #custom-nightlight { color: @base0A; }

          /* GitHub */
          #custom-github { color: @base05; }

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

      # Disable blueman StatusIcon plugin (waybar has bluetooth module)
      dconf.settings."org/blueman/plugins/statusicon" = {
        enabled = false;
      };
    }
  );
}
