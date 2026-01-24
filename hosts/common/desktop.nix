# Desktop environment configuration (Hyprland, SDDM, etc.)
{
  imports = [
    ../../modules/core/security.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/sddm.nix
    ../../modules/desktop/flatpak.nix
  ];
}
