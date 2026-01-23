# NOT for production use
{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

  virtualisation.memorySize = 4096;
  virtualisation.cores = 4;

  # Grab keyboard on hover so Super key works
  virtualisation.qemu.options = [
    "-display"
    "gtk,grab-on-hover=on"
  ];

  security.sudo.wheelNeedsPassword = false;

  users.users.javad = {
    initialPassword = lib.mkForce null;
    password = "test";
  };
}
