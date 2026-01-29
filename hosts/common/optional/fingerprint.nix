# Fingerprint reader support (ThinkPad P1 Gen 8)
{ pkgs, config, ... }:

let
  # Script to check if fingerprint is enabled based on lid state
  checkFingerprintEnabled = pkgs.writeScript "check-fingerprint-enabled" ''
    #!${pkgs.bash}/bin/bash
    # Return 0 (success) if fingerprint enabled (lid open or no lid), 1 if disabled (lid closed)
    lid_state=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | head -1)
    case "$lid_state" in
      *closed*) exit 1 ;;
    esac
    exit 0
  '';
in
{
  # Allow users to manage fprintd without password (for lid scripts)
  security.sudo.extraRules = [
    {
      groups = [ "users" ];
      commands = [
        {
          command = "${config.systemd.package}/bin/systemctl stop fprintd.service";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${config.systemd.package}/bin/systemctl start fprintd.service";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${config.systemd.package}/bin/systemctl restart fprintd.service";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

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
        args = [
          "quiet"
          "${checkFingerprintEnabled}"
        ];
      };
    };

    # Sudo with lid check
    sudo = {
      fprintAuth = true;
      rules.auth.fingerprint-check = {
        order = config.security.pam.services.sudo.rules.auth.fprintd.order - 10;
        control = "[success=ignore default=1]";
        modulePath = "${pkgs.pam}/lib/security/pam_exec.so";
        args = [
          "quiet"
          "${checkFingerprintEnabled}"
        ];
      };
    };

    # Polkit (for GUI privilege escalation) with lid check
    polkit-1 = {
      fprintAuth = true;
      rules.auth.fingerprint-check = {
        order = config.security.pam.services.polkit-1.rules.auth.fprintd.order - 10;
        control = "[success=ignore default=1]";
        modulePath = "${pkgs.pam}/lib/security/pam_exec.so";
        args = [
          "quiet"
          "${checkFingerprintEnabled}"
        ];
      };
    };
  };
}
