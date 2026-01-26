{
  config,
  pkgs,
  lib,
  flakeRoot,
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
    ];
    shell = pkgs.fish;
    initialPassword = lib.mkDefault "changeme";
  };

  programs.fish.enable = true;

  # Home-manager config selected by hostname
  home-manager.users.javad = import "${flakeRoot}/home/javad/${config.networking.hostName}";

  # Symlink /etc/nixos to user's editable git repo
  systemd.tmpfiles.rules = [
    "L+ /etc/nixos - - - - /home/javad/Dev/nixpille"
  ];
}
