# Lid switch handling for laptops
# Import this module in host-specific configs to enable power-aware lid behavior
{ pkgs, ... }:

let
  # Fingerprint management script - controls fprintd service based on lid state
  # Gracefully handles hosts without fingerprint support (ideapad)
  fingerprintCtl = pkgs.writeScriptBin "fingerprint-ctl" ''
    #!${pkgs.fish}/bin/fish

    function get_lid_state
      cat /proc/acpi/button/lid/*/state 2>/dev/null | string match -r 'open|closed'; or echo "unknown"
    end

    function has_fprintd
      systemctl list-unit-files fprintd.service >/dev/null 2>&1
    end

    function disable_fingerprint
      has_fprintd; and sudo systemctl stop fprintd.service 2>/dev/null; or true
    end

    function enable_fingerprint
      # Use restart to properly reset device claims
      has_fprintd; and sudo systemctl restart fprintd.service 2>/dev/null; or true
    end

    set cmd (test (count $argv) -gt 0; and echo $argv[1]; or echo "auto")

    switch $cmd
      case disable
        disable_fingerprint
      case enable
        enable_fingerprint
      case auto sync
        if test (get_lid_state) = "closed"
          disable_fingerprint
        else
          enable_fingerprint
        end
      case status
        echo "Lid: "(get_lid_state)
        if has_fprintd
          set fprintd_status (systemctl is-active fprintd.service 2>/dev/null; or echo "unknown")
          echo "fprintd: $fprintd_status"
        else
          echo "fprintd: not available"
        end
      case '*'
        echo "Usage: fingerprint-ctl {enable|disable|auto|status}"
        exit 1
    end
  '';

  lidCloseScript = pkgs.writeScript "lid-close" ''
    #!${pkgs.fish}/bin/fish
    # Stop fprintd service (sensor not reachable with lid closed)
    ${fingerprintCtl}/bin/fingerprint-ctl disable

    # Monitor switching handled by kanshi (profiles match connected outputs)
    # Only handle suspend: on battery with no external monitors
    set ac_online (cat /sys/class/power_supply/AC*/online 2>/dev/null; or cat /sys/class/power_supply/ACAD/online 2>/dev/null; or echo "0")
    set external_monitors (hyprctl monitors -j | ${pkgs.jq}/bin/jq '[.[] | select(.name != "eDP-1")] | length')

    if test "$external_monitors" -eq 0 -a "$ac_online" != "1"
      loginctl lock-session
      sleep 0.5
      systemctl suspend
    end
  '';

  lidOpenScript = pkgs.writeScript "lid-open" ''
    #!${pkgs.fish}/bin/fish
    # Start fprintd service (sensor accessible again)
    ${fingerprintCtl}/bin/fingerprint-ctl enable
  '';
in
{
  home.packages = [ fingerprintCtl ];

  wayland.windowManager.hyprland.settings = {
    # Sync fprintd state with lid on startup
    exec-once = [ "${fingerprintCtl}/bin/fingerprint-ctl auto" ];

    bindl = [
      ", switch:on:Lid Switch, exec, ${lidCloseScript}"
      ", switch:off:Lid Switch, exec, ${lidOpenScript}"
    ];
  };
}
