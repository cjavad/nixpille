# Shared binary cache configuration
# Used by ISO, hosts, and scripts
{ lib, ... }:

let
  # Extra substituters beyond cache.nixos.org
  extraSubstituters = [
    "https://hyprland.cachix.org"
    "https://nix-community.cachix.org"
    "https://vicinae.cachix.org"
  ];

  extraTrustedKeys = [
    "hyprland.cachix.org-1:a7pgxzMz7+VO9dXvamGIBD/FX5BsGNN7CQ56MWRspLU="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
  ];
in
{
  # NixOS module configuration
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
    ]
    ++ extraSubstituters;

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ]
    ++ extraTrustedKeys;
  };

  # Export values for scripts via environment file
  environment.etc."nixpille/cache.env".text = ''
    EXTRA_SUBSTITUTERS="${lib.concatStringsSep " " extraSubstituters}"
    EXTRA_TRUSTED_KEYS="${lib.concatStringsSep " " extraTrustedKeys}"
    NIX_FLAGS="--extra-substituters '${lib.concatStringsSep " " extraSubstituters}' --extra-trusted-public-keys '${lib.concatStringsSep " " extraTrustedKeys}'"
  '';
}
