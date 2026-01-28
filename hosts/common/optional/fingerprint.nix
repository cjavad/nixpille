# Fingerprint reader support (ThinkPad P1 Gen 8)
{ pkgs, config, ... }:

let
  # Script to check if fingerprint is enabled (marker file absent)
  checkFingerprintEnabled = pkgs.writeScript "check-fingerprint-enabled" ''
    #!${pkgs.bash}/bin/bash
    # Return 0 (success) if fingerprint enabled, 1 if disabled
    [ ! -f /run/fingerprint-disabled ]
  '';
in
{
  # Allow users to manage fprintd and marker file without password (for lid scripts)
  security.sudo.extraRules = [{
    groups = [ "users" ];
    commands = [
      { command = "${config.systemd.package}/bin/systemctl stop fprintd.service"; options = [ "NOPASSWD" ]; }
      { command = "${config.systemd.package}/bin/systemctl start fprintd.service"; options = [ "NOPASSWD" ]; }
      { command = "${pkgs.coreutils}/bin/touch /run/fingerprint-disabled"; options = [ "NOPASSWD" ]; }
      { command = "${pkgs.coreutils}/bin/rm -f /run/fingerprint-disabled"; options = [ "NOPASSWD" ]; }
    ];
  }];

  # Enable fprintd daemon with Touch OEM Driver support
  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-goodix;
    };
  };

  # PAM integration for fingerprint auth
  security.pam.services = {
    # SDDM: Disable fingerprint (broken UX - no feedback, appears frozen)
    sddm.fprintAuth = false;

    # Hyprlock: Enable fingerprint with lid check
    hyprlock = {
      fprintAuth = true;
      rules.auth.fingerprint-check = {
        order = config.security.pam.services.hyprlock.rules.auth.fprintd.order - 10;
        control = "[success=ignore default=1]";
        modulePath = "${pkgs.pam}/lib/security/pam_exec.so";
        args = [ "quiet" "${checkFingerprintEnabled}" ];
      };
    };

    # Sudo with lid check
    sudo = {
      fprintAuth = true;
      rules.auth.fingerprint-check = {
        order = config.security.pam.services.sudo.rules.auth.fprintd.order - 10;
        control = "[success=ignore default=1]";
        modulePath = "${pkgs.pam}/lib/security/pam_exec.so";
        args = [ "quiet" "${checkFingerprintEnabled}" ];
      };
    };

    # Polkit (for GUI privilege escalation) with lid check
    polkit-1 = {
      fprintAuth = true;
      rules.auth.fingerprint-check = {
        order = config.security.pam.services.polkit-1.rules.auth.fprintd.order - 10;
        control = "[success=ignore default=1]";
        modulePath = "${pkgs.pam}/lib/security/pam_exec.so";
        args = [ "quiet" "${checkFingerprintEnabled}" ];
      };
    };
  };
}
