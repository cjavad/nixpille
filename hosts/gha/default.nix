{ pkgs, lib, ... }:

{
  imports = [
    ../../hosts/common
  ];

  networking.hostName = "gha";

  boot.loader.grub.devices = [ "/dev/sda" ];
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  environment.systemPackages = with pkgs; [
    git
    gh
    neovim
    curl
    jq
  ];

  system.stateVersion = "25.11";
}
