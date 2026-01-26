# Minimal GDM display manager (for fingerprint support)
{ pkgs, lib, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
      autoSuspend = false; # Prevent auto-suspend on login screen
    };
  };

  # Default session
  services.displayManager.defaultSession = "hyprland-uwsm";

  # Minimal GNOME services for GDM (avoid pulling full GNOME)
  services.gnome.gnome-keyring.enable = lib.mkDefault true;

  # GDM uses gnome-shell for theming - Stylix handles this via targets.gnome
  # No additional packages needed - Stylix provides the theme
}
