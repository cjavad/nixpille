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

  virtualisation.memorySize = 4096;
  virtualisation.diskSize = 2048;
  virtualisation.cores = 4;

  virtualisation.qemu.options = [
    "-display"
    "gtk,grab-on-hover=on"
  ];

  security.sudo-rs.wheelNeedsPassword = lib.mkForce false;

  users.users.javad = {
    initialPassword = lib.mkForce "test";
  };
}
