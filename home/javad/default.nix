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

  systemd.tmpfiles.rules = [
    "L+ /etc/nixos - - - - /home/javad/Dev/nixpille"
  ];
}
