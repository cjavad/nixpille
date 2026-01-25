# Desktop environment configuration
{ pkgs, ... }:

{
  imports = [
    ./audio.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/sddm.nix
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];
}
