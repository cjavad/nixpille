{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ../common/global
    ../common/optional/hyprland.nix
    ../common/optional/sddm.nix
    ../common/optional/stylix.nix
    ../common/optional/audio.nix
    ../common/users/javad.nix
    ../../modules/virtualisation/qemu-guest.nix
  ];

  networking.hostName = "vm";

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  system.stateVersion = "25.11";
}
