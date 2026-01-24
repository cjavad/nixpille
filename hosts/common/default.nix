# Shared system configuration for all hosts
{ pkgs, lib, ... }:

{
  imports = [
    ../../modules/core/caches.nix
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      builders-use-substitutes = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
  boot.loader.grub.configurationLimit = lib.mkDefault 10;

  nixpkgs.config.allowUnfree = true;
  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.kernelParams = [ "quiet" "splash" ];
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "fs.inotify.max_user_watches" = 524288;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.tlp.enable = true;

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

  networking.networkmanager.enable = true;
  console.keyMap = "dk";

  services.xserver.xkb = {
    layout = "dk,us";
    options = "grp:alt_shift_toggle";
  };

  zramSwap.enable = true;
  boot.tmp.useTmpfs = true;

  services.fwupd.enable = true;

  systemd.services.NetworkManager-wait-online.enable = false;
}
