# Hyprland NixOS configuration
# Pair with home/common/linux-desktop for full Hyprland setup
{ pkgs, config, ... }:

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
  security.pam.services.login = {
    enableGnomeKeyring = true;
    # Capture password for keyring BEFORE fingerprint can short-circuit auth
    # Default gnome_keyring is order 12200, fprintd is 11400
    # This rule at 11300 ensures password is captured first
    rules.auth.gnome_keyring_early = {
      order = 11300;
      control = "optional";
      modulePath = "${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so";
    };
  };

  # GPG agent
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

  # Nautilus support (trash, network mounts, MTP, thumbnails)
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  environment.systemPackages = [ pkgs.file-roller ];

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];
}
