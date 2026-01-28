# Lid switch handling for laptops
# Import this module in host-specific configs to enable power-aware lid behavior
{ pkgs, ... }:

let
  # Unified fingerprint management script
  # Handles both fprintd service and PAM marker file
  fingerprintCtl = pkgs.writeScriptBin "fingerprint-ctl" ''
    #!${pkgs.fish}/bin/fish
    set MARKER_FILE "/run/fingerprint-disabled"

    function get_lid_state
      cat /proc/acpi/button/lid/*/state 2>/dev/null | string match -r 'open|closed'; or echo "unknown"
    end

    function disable_fingerprint
      sudo touch $MARKER_FILE
      sudo systemctl stop fprintd.service 2>/dev/null; or true
    end

    function enable_fingerprint
      sudo rm -f $MARKER_FILE
      sudo systemctl start fprintd.service 2>/dev/null; or true
    end

    set cmd (test (count $argv) -gt 0; and echo $argv[1]; or echo "auto")

    switch $cmd
      case disable
        disable_fingerprint
      case enable
        enable_fingerprint
      case auto sync
        # Sync fingerprint state with lid state
        if test (get_lid_state) = "closed"
          disable_fingerprint
        else
          enable_fingerprint
        end
      case status
        echo "Lid: "(get_lid_state)
        if test -f $MARKER_FILE
          echo "Fingerprint: disabled"
        else
          echo "Fingerprint: enabled"
        end
      case '*'
        echo "Usage: fingerprint-ctl {enable|disable|auto|status}"
        exit 1
    end
  '';

  lidCloseScript = pkgs.writeScript "lid-close" ''
    #!${pkgs.fish}/bin/fish
    # Disable fingerprint auth (sensor not reachable with lid closed)
    ${fingerprintCtl}/bin/fingerprint-ctl disable

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
    # Re-enable fingerprint auth (sensor accessible again)
    ${fingerprintCtl}/bin/fingerprint-ctl enable
  '';
in
{
  home.packages = [ fingerprintCtl ];

  wayland.windowManager.hyprland.settings = {
    # Check lid state on startup (stateless - handles boot with lid closed)
    exec-once = [ "${fingerprintCtl}/bin/fingerprint-ctl auto" ];

    bindl = [
      ", switch:on:Lid Switch, exec, ${lidCloseScript}"
      ", switch:off:Lid Switch, exec, ${lidOpenScript}"
    ];
  };
}
