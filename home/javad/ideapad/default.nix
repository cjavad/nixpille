# Home configuration for ideapad
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
    monitors.internal = {
      connector = "eDP-1";
      width = 2560;
      height = 1440;
      refreshRate = 120;
      scale = 1.6;
    };
    groups.laptop = {
      monitors = [ "internal" ];
    };
    defaultGroup = "laptop";
  };
}
