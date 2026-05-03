{ pkgs, lib, ... }:

{
  boot = {
    # Bootloader (systemd-boot for EFI systems)
    loader.systemd-boot.enable = lib.mkDefault true;
    loader.systemd-boot.configurationLimit = lib.mkDefault 10;
    loader.efi.canTouchEfiVariables = lib.mkDefault false;
    loader.grub.configurationLimit = lib.mkDefault 10;
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-lts;
    kernelModules = [
      "msr"
      "hid-logitech-dj"
    ];
    kernelParams = [
      "quiet"
      "splash"
      "msr.allow_writes=off"
      "i915.enable_psr=0"
      "i915.enable_dc=0"
      "intel_idle.max_cstate=2"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "mem_sleep_default=s2idle"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "fs.inotify.max_user_watches" = 524288;
    };
    tmp.useTmpfs = true;
  };
}
