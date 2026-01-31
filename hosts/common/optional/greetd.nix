# greetd display manager with agreety greeter
{ ... }:

{
  imports = [
    ../../../modules/desktop/greetd.nix
  ];

  # Keyring PAM integration for greetd
  security.pam.services.greetd.enableGnomeKeyring = true;
}
