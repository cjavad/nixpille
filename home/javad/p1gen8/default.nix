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

  # Monitors managed by kanshi (see home/common/wayland/kanshi.nix)
}
