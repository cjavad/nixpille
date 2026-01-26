{ pkgs, lib, ... }:

{
  boot = {
    # Bootloader (systemd-boot for EFI systems)
    loader.systemd-boot.enable = lib.mkDefault true;
    loader.systemd-boot.configurationLimit = lib.mkDefault 10;
    loader.efi.canTouchEfiVariables = lib.mkDefault true;
    loader.grub.configurationLimit = lib.mkDefault 10;
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = [
      "quiet"
      "splash"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "fs.inotify.max_user_watches" = 524288;
    };
    tmp.useTmpfs = true;
  };
}
