# NixOS user definition for javad
{
  config,
  pkgs,
  lib,
  ...
}:

{
  time.timeZone = "Europe/Copenhagen";

  users.users.javad = {
    isNormalUser = true;
    description = "Javad";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "docker"
    ];
    shell = pkgs.fish;
    initialPassword = lib.mkDefault "changeme";
  };

  programs.fish.enable = true;
  services.flatpak.enable = true;

  # Cursed: first user wins /etc/nixos. Others use --flake explicitly.
  systemd.tmpfiles.rules = [
    "L+ /etc/nixos - - - - /home/javad/Dev/nixpille"
  ];
}
