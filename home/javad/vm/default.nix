# Home configuration for vm (full desktop for testing)
{
  imports = [
    ../../common/global
    # Desktop without secrets (for fresh VM testing)
    ../../common/wayland
    ../../common/hyprland
    ../../common/terminals/kitty.nix
    ../../common/browsers/zen.nix
    ../../common/launchers/vicinae.nix
    ../../common/development
    ../../common/applications
  ];
}
