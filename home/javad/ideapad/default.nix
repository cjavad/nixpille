# Home configuration for ideapad (full desktop workstation)
{ lib, ... }:

{
  imports = [
    ../../common/global
    ../../common/linux-desktop
    ../../common/development
    ../../common/applications
    ../secrets.nix
  ];

  # IdeaPad display scaling
  wayland.windowManager.hyprland.settings.monitor = lib.mkForce [
    "eDP-1,preferred,auto,1.6"
    ",preferred,auto,1"
  ];
}
