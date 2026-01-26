{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

let
  installScript = pkgs.writeScriptBin "nixpille-install" (
    builtins.readFile ../../../ops/installer/nixpille-install
  );
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    (import ../../cache).nixosModule
  ];

  # Minimal ISO - downloads everything from network
  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
  image.baseName = lib.mkForce "nixpille";
  nixpkgs.config.allowUnfree = true;

  # Locale
  console.keyMap = "dk";
  i18n.defaultLocale = "en_US.UTF-8";

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Network
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # Shell
  programs.fish.enable = true;

  # Live user
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    initialHashedPassword = "";
    shell = lib.mkForce pkgs.fish;
  };

  security.sudo.wheelNeedsPassword = false;
  services.getty.autologinUser = "nixos";

  # Packages
  environment.systemPackages = with pkgs; [
    installScript
    dialog
    git
    neovim
    parted
    gptfdisk
    dosfstools
    e2fsprogs
    btrfs-progs
    curl
    wget
    pciutils
    usbutils
    htop
    file
  ];

  # Disko config for installer
  environment.etc."nixpille/disko/standard.nix".source = ../../disko/standard.nix;

  # Fish config for live environment
  programs.fish.interactiveShellInit = ''
    set -gx EDITOR nvim
    set -gx VISUAL nvim

    function fish_greeting
      echo ""
      set_color cyan
      echo "  nixpille installer"
      set_color normal
      echo ""
      echo "  Run 'nixpille-install' to begin"
      echo "  Run 'nmtui' to configure network"
      echo ""
    end
  '';

  # MOTD
  environment.etc."motd".text = ''

    ┌──────────────────────────────────────────────────────────┐
    │                   nixpille installer                     │
    ├──────────────────────────────────────────────────────────┤
    │  nixpille-install    Start installation                  │
    │  nmtui               Configure network                   │
    │  lsblk               List disks                          │
    └──────────────────────────────────────────────────────────┘

  '';

  system.stateVersion = "25.11";
}
