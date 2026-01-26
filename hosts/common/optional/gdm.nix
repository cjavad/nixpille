# GDM display manager (with fingerprint support)
{ lib, ... }:

{
  imports = [
    ../../../modules/desktop/gdm.nix
  ];

  # Keyring PAM integration for GDM
  security.pam.services.gdm-password.enableGnomeKeyring = true;

  # Ensure SDDM is disabled when using GDM
  services.displayManager.sddm.enable = lib.mkForce false;
}
