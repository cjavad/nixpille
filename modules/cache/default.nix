rec {
  # Single source of truth - each cache as a pair
  caches = [
    {
      url = "https://hyprland.cachix.org";
      key = "hyprland.cachix.org-1:a7pgxzMz7+VO9dXvamGIBD/FX5BsGNN7CQ56MWRspLU=";
    }
    {
      url = "https://nix-community.cachix.org";
      key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    }
    {
      url = "https://vicinae.cachix.org";
      key = "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=";
    }
  ];

  # Derived outputs for different consumers
  substituters = map (c: c.url) caches;
  trustedPublicKeys = map (c: c.key) caches;

  # For flake.nix nixConfig
  nixConfig = {
    extra-substituters = substituters;
    extra-trusted-public-keys = trustedPublicKeys;
  };

  # NixOS module
  nixosModule =
    { lib, ... }:
    {
      nix.settings = {
        substituters = [ "https://cache.nixos.org" ] ++ substituters;
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ]
        ++ trustedPublicKeys;
      };

      environment.etc."nixpille/cache.env".text = ''
        # Informational only - caches are configured via flake.nix nixConfig
        EXTRA_SUBSTITUTERS="${lib.concatStringsSep " " substituters}"
        EXTRA_TRUSTED_KEYS="${lib.concatStringsSep " " trustedPublicKeys}"
      '';
    };
}
