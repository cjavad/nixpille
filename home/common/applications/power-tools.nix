{ pkgs, ... }:

let
  battery-health = pkgs.writeShellScriptBin "battery-health" ''
    set -eu

    found=0

    for battery in /sys/class/power_supply/BAT*; do
      [ -d "$battery" ] || continue
      found=1

      name="$(basename "$battery")"
      status="$(cat "$battery/status" 2>/dev/null || echo unknown)"
      capacity="$(cat "$battery/capacity" 2>/dev/null || echo unknown)"
      cycle_count="$(cat "$battery/cycle_count" 2>/dev/null || echo unknown)"

      full_now=""
      full_design=""
      unit="uWh"

      if [ -r "$battery/energy_full" ] && [ -r "$battery/energy_full_design" ]; then
        full_now="$(cat "$battery/energy_full")"
        full_design="$(cat "$battery/energy_full_design")"
      elif [ -r "$battery/charge_full" ] && [ -r "$battery/charge_full_design" ]; then
        full_now="$(cat "$battery/charge_full")"
        full_design="$(cat "$battery/charge_full_design")"
        unit="uAh"
      fi

      health="unknown"
      wear="unknown"
      if [ -n "$full_now" ] && [ -n "$full_design" ] && [ "$full_design" -gt 0 ]; then
        health="$(awk "BEGIN { printf \"%.1f\", ($full_now / $full_design) * 100 }")"
        wear="$(awk "BEGIN { printf \"%.1f\", 100 - (($full_now / $full_design) * 100) }")"
      fi

      echo "$name"
      echo "  status: $status"
      echo "  capacity: $capacity%"
      echo "  cycle_count: $cycle_count"
      if [ -n "$full_now" ] && [ -n "$full_design" ]; then
        echo "  full_now: $full_now $unit"
        echo "  full_design: $full_design $unit"
      fi
      echo "  health: $health%"
      echo "  wear: $wear%"
      echo
    done

    if [ "$found" -eq 0 ]; then
      echo "No batteries found under /sys/class/power_supply." >&2
      exit 1
    fi
  '';
in
{
  home.packages = with pkgs; [
    acpi # Quick battery/AC state in the terminal
    s-tui # Terminal-based CPU stress test & monitoring
    stress-ng # Stress testing tool (used by s-tui)
    powertop # Power consumption analysis
    battery-health
  ];
}
