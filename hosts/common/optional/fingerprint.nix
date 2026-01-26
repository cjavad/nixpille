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
    # GDM login (fingerprint works natively with GDM)
    gdm-password.fprintAuth = true;

    # Screen locker
    hyprlock.fprintAuth = true;

    # Sudo (optional - comment out if you prefer password-only)
    sudo.fprintAuth = true;

    # Polkit (for GUI privilege escalation)
    polkit-1.fprintAuth = true;
  };
}
