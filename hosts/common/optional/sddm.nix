# SDDM display manager
{ ... }:

{
  imports = [
    ../../../modules/desktop/sddm.nix
  ];

  # Keyring PAM integration for SDDM
  security.pam.services.sddm.enableGnomeKeyring = true;
}
