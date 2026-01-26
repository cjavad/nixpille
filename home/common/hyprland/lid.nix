# Lid switch handling for laptops
# Import this module in host-specific configs to enable power-aware lid behavior
{ pkgs, ... }:

let
  lidCloseScript = pkgs.writeScript "lid-close" ''
    #!${pkgs.fish}/bin/fish
    # Check if on AC power
    set ac_online (cat /sys/class/power_supply/AC*/online 2>/dev/null; or cat /sys/class/power_supply/ACAD/online 2>/dev/null; or echo "0")

    # Check for external monitors (any monitor besides eDP-1)
    set external_monitors (hyprctl monitors -j | ${pkgs.jq}/bin/jq '[.[] | select(.name != "eDP-1")] | length')

    if test "$external_monitors" -gt 0
      # External monitors connected - just disable internal display
      hyprctl dispatch dpms off eDP-1
    else if test "$ac_online" = "1"
      # On AC power - DPMS off all monitors
      hyprctl dispatch dpms off
    else
      # On battery - lock and suspend
      loginctl lock-session
      sleep 0.5
      systemctl suspend
    end
  '';

  lidOpenScript = pkgs.writeScript "lid-open" ''
    #!${pkgs.fish}/bin/fish
    hyprctl dispatch dpms on
  '';
in
{
  wayland.windowManager.hyprland.settings.bindl = [
    ", switch:on:Lid Switch, exec, ${lidCloseScript}"
    ", switch:off:Lid Switch, exec, ${lidOpenScript}"
  ];
}
