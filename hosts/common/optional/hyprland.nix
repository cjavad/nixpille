# Hyprland NixOS configuration
# Pair with home/common/linux-desktop for full Hyprland setup
{ pkgs, ... }:

{
  imports = [
    ../../../modules/desktop/hyprland.nix
  ];

  # XDG portals (required for Hyprland)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Flatpak support
  services.flatpak.enable = true;

  # GNOME Keyring - auto-unlock via PAM
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # GPG agent
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];
}
