{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = pkgs-unstable.hyprland;
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
  };

  # Upstream NixOS module hardcodes binPath to "Hyprland" instead of
  # "start-hyprland", causing a startup warning. Override until fixed.
  # https://github.com/NixOS/nixpkgs/issues/476375
  programs.uwsm.waylandCompositors.hyprland.binPath =
    lib.mkForce "/run/current-system/sw/bin/start-hyprland";

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    # Electron apps native Wayland
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
      };
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
      };
    };
  };

  security.pam.services.hyprlock = {
    enableGnomeKeyring = true;
  };

  systemd.user.services.hyprpolkitagent = {
    description = "Hyprland Polkit Authentication Agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
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
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
      Restart = "on-failure";
    };
  };
}
