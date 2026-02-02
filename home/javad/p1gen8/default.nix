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
    };
    groups = {
      docked = {
        monitors = [
          "internal"
          "dell-middle"
          "dell-left"
        ];
      };
      laptop = {
        monitors = [ "internal" ];
      };
    };
    defaultGroup = "docked";
  };
}
