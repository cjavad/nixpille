# nixpille ISO - Installer and Live Desktop
#
# Boot menu options:
# - Install NixOS: Boots to TTY and auto-runs installer
# - Live Desktop: Boots into full Hyprland desktop (same as installed system)
{
  config,
  pkgs,
  lib,
  modulesPath,
  inputs,
  ...
}:

let
  installScript = pkgs.writeShellScriptBin "nixpille-install" (
    builtins.readFile ../../../scripts/installer-nixpille.sh
  );
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    # Shared configurations (same as regular hosts)
    ../../../hosts/common/desktop.nix
    ../../cache
  ];

  # ===========================================
  # ISO Configuration
  # ===========================================

  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  image.baseName = lib.mkForce "nixpille";
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # ===========================================
  # Networking
  # ===========================================

  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # ===========================================
  # Live User (same setup as javad)
  # ===========================================

  programs.fish.enable = true;

  users.users.nixos = {
    isNormalUser = true;
    description = "Live User";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];
    initialHashedPassword = "";
    shell = pkgs.fish;
  };

  security.sudo.wheelNeedsPassword = false;

  # ===========================================
  # Display Manager - Conditional on boot mode
  # ===========================================

  # Override SDDM to auto-login for live session
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  # ===========================================
  # System Packages
  # ===========================================

  environment.systemPackages = with pkgs; [
    # Installation tools
    installScript
    dialog

    # Core
    git
    vim
    neovim

    # Partitioning
    parted
    gptfdisk
    dosfstools
    e2fsprogs

    # Networking
    curl
    wget
    networkmanagerapplet

    # Utilities
    pciutils
    usbutils
    htop
    file
    unzip

    # Extra desktop apps for live session
    pavucontrol
    firefox
    nautilus
    fuzzel
  ];

  # ===========================================
  # Configuration Files
  # ===========================================

  # Include disko config
  environment.etc."nixpille/disko/standard.nix".source = ../../disko/standard.nix;

  # Link javad's dotfiles for the live user
  environment.etc."skel/.config/hypr".source = ../../../users/javad/dotfiles/hypr;
  environment.etc."skel/.config/waybar".source = ../../../users/javad/dotfiles/waybar;
  environment.etc."skel/.config/kitty".source = ../../../users/javad/dotfiles/kitty;
  environment.etc."skel/.config/mako".source = ../../../users/javad/dotfiles/mako;
  environment.etc."skel/.config/fish".source = ../../../users/javad/dotfiles/fish;

  # Copy dotfiles to live user home
  system.activationScripts.copyUserConfig = ''
    if [ -d /home/nixos ]; then
      cp -rn /etc/skel/. /home/nixos/ 2>/dev/null || true
      chown -R nixos:users /home/nixos/.config 2>/dev/null || true
    fi
  '';

  # Welcome message
  environment.etc."motd".text = ''

    ╔══════════════════════════════════════════════════════════════╗
    ║                 Welcome to nixpille                          ║
    ╠══════════════════════════════════════════════════════════════╣
    ║                                                              ║
    ║  To install NixOS, run: nixpille-install                     ║
    ║                                                              ║
    ║  Keybindings:                                                ║
    ║    ALT+Return    - Terminal                                  ║
    ║    ALT+Space     - Vicinae launcher                          ║
    ║    ALT+Q         - Close window                              ║
    ║    ALT+1-9       - Switch workspace                          ║
    ║    ALT+Shift     - Toggle keyboard layout (dk/us)            ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝

  '';
}
