# nixpille ISO - Minimal installer
#
# Boots to TTY with autologin and MOTD
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

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Display MOTD on login
      if test -e /etc/motd; and status is-login
        cat /etc/motd
      end
    '';
  };

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
    shell = lib.mkForce pkgs.fish;
  };

  security.sudo.wheelNeedsPassword = false;

  # ===========================================
  # TTY Autologin
  # ===========================================

  services.getty.autologinUser = "nixos";

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

    # Utilities
    pciutils
    usbutils
    htop
    file
    unzip
  ];

  # ===========================================
  # Configuration Files
  # ===========================================

  # Include disko config
  environment.etc."nixpille/disko/standard.nix".source = ../../disko/standard.nix;

  # Fish shell config
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
    ║  Useful commands:                                            ║
    ║    nmtui           - Configure network                       ║
    ║    htop            - System monitor                          ║
    ║    lsblk           - List disks                              ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝

  '';
}
