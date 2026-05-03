{ pkgs, ... }:

let
  lowThreshold = 25;
  criticalThreshold = 12;
  actionThreshold = 7;

  batteryAlertCheck = pkgs.writeShellScriptBin "battery-alert-check" ''
    set -eu

    battery=""
    for candidate in /sys/class/power_supply/BAT*; do
      [ -d "$candidate" ] || continue
      battery="$candidate"
      break
    done

    [ -n "$battery" ] || exit 0

    status="$(cat "$battery/status" 2>/dev/null || echo Unknown)"
    capacity="$(cat "$battery/capacity" 2>/dev/null || echo)"

    case "$capacity" in
      ""|*[!0-9]*)
        exit 0
        ;;
    esac

    state_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/battery-alerts"
    state_file="$state_dir/last-level"
    mkdir -p "$state_dir"

    last_level=""
    if [ -r "$state_file" ]; then
      last_level="$(cat "$state_file" 2>/dev/null || true)"
    fi

    case "$status" in
      Charging|Full|"Not charging")
        rm -f "$state_file"
        exit 0
        ;;
    esac

    level="normal"
    urgency="normal"
    title=""
    body=""

    if [ "$capacity" -le ${toString actionThreshold} ]; then
      level="action"
      urgency="critical"
      title="Battery at $capacity%"
      body="Battery is extremely low. UPower power-off threshold is ${toString actionThreshold}%."
    elif [ "$capacity" -le ${toString criticalThreshold} ]; then
      level="critical"
      urgency="critical"
      title="Battery critical at $capacity%"
      body="Connect power now."
    elif [ "$capacity" -le ${toString lowThreshold} ]; then
      level="low"
      urgency="normal"
      title="Battery low at $capacity%"
      body="Plug in soon."
    fi

    if [ "$level" = "normal" ]; then
      rm -f "$state_file"
      exit 0
    fi

    if [ "$level" = "$last_level" ]; then
      exit 0
    fi

    printf '%s\n' "$level" > "$state_file"

    exec ${pkgs.libnotify}/bin/notify-send \
      -a "battery-monitor" \
      -u "$urgency" \
      "$title" \
      "$body"
  '';

  batteryAlertTest = pkgs.writeShellScriptBin "battery-alert-test" ''
    set -eu

    level="''${1:-critical}"

    case "$level" in
      low)
        exec ${pkgs.libnotify}/bin/notify-send -a "battery-monitor" -u normal \
          "Battery low at ${toString lowThreshold}%" \
          "Test notification from battery-alert-test."
        ;;
      critical)
        exec ${pkgs.libnotify}/bin/notify-send -a "battery-monitor" -u critical \
          "Battery critical at ${toString criticalThreshold}%" \
          "Test notification from battery-alert-test."
        ;;
      action)
        exec ${pkgs.libnotify}/bin/notify-send -a "battery-monitor" -u critical \
          "Battery at ${toString actionThreshold}%" \
          "Test notification from battery-alert-test."
        ;;
      *)
        echo "usage: battery-alert-test [low|critical|action]" >&2
        exit 2
        ;;
    esac
  '';
in
{
  home.packages = [
    batteryAlertCheck
    batteryAlertTest
  ];

  systemd.user.services.battery-alert = {
    Unit = {
      Description = "Battery notification check";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${batteryAlertCheck}/bin/battery-alert-check";
    };
  };

  systemd.user.timers.battery-alert = {
    Unit.Description = "Run battery notification checks";
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "30s";
      AccuracySec = "5s";
      Unit = "battery-alert.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
