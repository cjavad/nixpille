{ ... }:

{
  imports = [
    ./nix.nix
    ./boot.nix
    ./locale.nix
    ./hardware.nix
    ./network.nix
    ./security.nix
    (import ../../../modules/cache).nixosModule
  ];
}
