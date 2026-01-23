{ pkgs, lib, ... }:

{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Binary caches
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://vicinae.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+VO9dXvamGIBD/FX5BsGNN7CQ56MWRspLU="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
      # Performance
      auto-optimise-store = true;
      builders-use-substitutes = true;
      # Allow wheel group to manage nix
      trusted-users = [ "root" "@wheel" ];
    };

    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Limit boot generations
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
  boot.loader.grub.configurationLimit = lib.mkDefault 10;

  nixpkgs.config.allowUnfree = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    tree
    unzip
    jq
    yq-go
    go-task
    bitwarden-cli
    sops
    age
  ];

  networking.networkmanager.enable = true;
  console.keyMap = "dk";

  # Used by Wayland compositors
  services.xserver.xkb = {
    layout = "dk,us";
    options = "grp:alt_shift_toggle"; # Alt+Shift to switch layouts
  };

  # Performance optimizations
  zramSwap.enable = true; # Compressed RAM swap (better than disk)
  boot.tmp.useTmpfs = true; # /tmp in RAM

  # Firmware updates
  services.fwupd.enable = true;

  # Faster boot
  systemd.services.NetworkManager-wait-online.enable = false;

  # Security hardening (sensible defaults)
  security.protectKernelImage = true;
}
