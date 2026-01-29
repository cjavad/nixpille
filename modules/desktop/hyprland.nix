{ pkgs, pkgs-unstable, ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = pkgs-unstable.hyprland;
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
  };

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    MOZ_ENABLE_WAYLAND = "1";
    # Electron apps native Wayland
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  security.pam.services.hyprlock = {
    enableGnomeKeyring = true;
  };

  systemd.user.services.hyprpolkitagent = {
    description = "Hyprland Polkit Authentication Agent";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs-unstable.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  environment.systemPackages = [
    pkgs.brightnessctl
    pkgs.swayosd
    pkgs-unstable.hyprlock
    pkgs-unstable.hypridle
    pkgs-unstable.hyprpolkitagent
  ];

  # SwayOSD server (libinput backend for brightness keys)
  systemd.user.services.swayosd = {
    description = "SwayOSD LibInput Backend";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
      Restart = "on-failure";
    };
  };
}
