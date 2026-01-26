# Full Linux desktop environment (Hyprland + Wayland + apps)
# Shortcut for common desktop workstation setup
{
  imports = [
    ../secrets
    ../wayland
    ../hyprland
    ../terminals/kitty.nix
    ../browsers/zen.nix
    ../launchers/vicinae.nix
  ];
}
