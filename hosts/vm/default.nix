{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ../../modules/profiles/vm.nix
    ../../modules/users/javad.nix
  ];

  networking.hostName = "vm";

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  networking.firewall.enable = true;
  system.stateVersion = "25.11";
}
