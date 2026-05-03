# Home configuration for p1gen8 (full desktop workstation)
{ lib, ... }:

{
  imports = [
    ../../common/global
    ../../common/linux-desktop
    ../../common/development
    ../../common/applications
    ../../common/hyprland/lid.nix
    ../secrets.nix
  ];

  # Laptop: show battery in waybar
  custom.waybar.showBattery = true;

  # Unified custom shell. `np <subcommand>` is the entrypoint; symlinks
  # `monitors`/`greeter`/`locker`/`shelld` hit the matching subcommand
  # directly via argv[0] dispatch. Reads layout from `custom.monitors`
  # below, so there's exactly one source of truth for monitor groups.
  custom.nixpille = {
    enable = true;
    # Disabled until you've rebuilt with the new safety guards (auto-resolve
    # + apply_all fallback). The fixed binary lands automatically with this
    # rebuild; flip back to `true` after verifying `np monitors auto`.
    enableShelld = false;
    battery.lowThreshold = 20;
    battery.criticalThreshold = 10;
  };

  # Monitor configuration
  custom.monitors = {
    monitors = {
      internal = {
        connector = "eDP-1";
        width = 3200;
        height = 2000;
        refreshRate = 120;
        scale = 1.6;
      };
      dell-left = {
        edid = "Dell Inc. DELL P2314H J8J3146IBZ8B";
        width = 1920;
        height = 1080;
        scale = 1.25;
      };
      dell-middle = {
        edid = "Dell Inc. DELL P2414H 36WJX37G044L";
        width = 1920;
        height = 1080;
        scale = 1.25;
      };
      asus-vg249 = {
        edid = "ASUSTek COMPUTER INC ASUS VG249 0x00011D4C";
        width = 1920;
        height = 1080;
        refreshRate = 144.01;
        scale = 1.25;
      };
      lg-ultragear = {
        edid = "LG Electronics LG ULTRAGEAR 201MARZLGV38";
        width = 2560;
        height = 1440;
        refreshRate = 143.97;
        scale = 1.25;
      };
    };
    groups = {
      docked = {
        monitors = [
          "internal"
          "dell-middle"
          "dell-left"
        ];
        overrides.internal.scale = 2.0;
      };
      home-docked = {
        monitors = [
          "asus-vg249"
          "lg-ultragear"
        ];
      };
      laptop = {
        monitors = [ "internal" ];
      };
    };
    defaultGroup = "home-docked";
  };
}
