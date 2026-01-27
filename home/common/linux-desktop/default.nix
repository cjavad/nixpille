# Full Linux desktop environment (Hyprland + Wayland + apps)
# Shortcut for common desktop workstation setup
# Note: secrets module imported separately via user's secrets.nix
{
  imports = [
    ../wayland
    ../hyprland
    ../terminals/kitty.nix
    ../browsers/zen.nix
    ../launchers/vicinae.nix
  ];
}
