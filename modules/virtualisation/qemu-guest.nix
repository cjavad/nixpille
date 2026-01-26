{
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;

  virtualisation = {
    memorySize = 8192;
    diskSize = 4096;
    cores = 4;

    # Speed optimizations for 9p
    msize = 104857600; # 100MB 9p packet size (default is tiny)
    writableStoreUseTmpfs = true; # RAM-backed writable layer
    useEFIBoot = false; # BIOS is faster than EFI

    # Use virtio for everything
    graphics = true;

    qemu.options = [
      "-display"
      "gtk,grab-on-hover=on"
      "-cpu"
      "host"
      "-enable-kvm"
    ];
  };

  security.sudo-rs.wheelNeedsPassword = lib.mkForce false;

  users.users.javad = {
    initialPassword = lib.mkForce "test";
  };
}
