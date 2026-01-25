{
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    vim
  ];
}
