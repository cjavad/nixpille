{
  config,
  pkgs,
  lib,
  modulesPath,
  inputs,
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

  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  image.baseName = lib.mkForce "nixpille";
  nixpkgs.config.allowUnfree = true;

  # Danish keyboard as default (can be changed in installer)
  console.keyMap = "dk";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
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
  services.getty.autologinUser = "nixos";

  environment.systemPackages = with pkgs; [
    installScript
    dialog
    git
    neovim
    parted
    gptfdisk
    dosfstools
    e2fsprogs
    curl
    wget
    pciutils
    usbutils
    htop
    file
    unzip
  ];

  environment.etc."nixpille/disko/standard.nix".source = ../../disko/standard.nix;
  environment.etc."nixpille/repo".source = inputs.self;
  environment.etc."skel/.config/fish".source = ../../../home/javad/dotfiles/fish;

  system.activationScripts.copyUserConfig = ''
    if [ -d /home/nixos ]; then
      cp -rn /etc/skel/. /home/nixos/ 2>/dev/null || true
      chown -R nixos:users /home/nixos/.config 2>/dev/null || true
    fi
  '';

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
