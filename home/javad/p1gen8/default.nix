# Home configuration for p1gen8 (full desktop workstation)
{ lib, ... }:

{
  imports = [
    ../../common/global
    ../../common/linux-desktop
    ../../common/development
    ../../common/applications
    ../secrets.nix
  ];

  # P1 Gen8: 3.2K display - use Hyprland recommended 1.6
  wayland.windowManager.hyprland.settings.monitor = lib.mkForce [
    "eDP-1,preferred,auto,1.6"
    ",preferred,auto,1"
  ];
}
