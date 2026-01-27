# Fingerprint reader support (ThinkPad P1 Gen 8)
{ pkgs, ... }:

{
  # Enable fprintd daemon with Touch OEM Driver support
  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-goodix;
      # If Goodix doesn't work, try: pkgs.libfprint-2-tod1-goodix-550a
      # or pkgs.libfprint-2-tod1-elan
    };
  };

  # PAM integration for fingerprint auth
  security.pam.services = {
    # SDDM: Disable fingerprint (broken UX - no feedback, appears frozen)
    # Workaround: Press Enter on empty password field, then touch sensor
    sddm.fprintAuth = false;

    # Hyprlock: Enable fingerprint (supports parallel auth in recent versions)
    hyprlock.fprintAuth = true;

    # Sudo
    sudo.fprintAuth = true;

    # Polkit (for GUI privilege escalation)
    polkit-1.fprintAuth = true;
  };
}
