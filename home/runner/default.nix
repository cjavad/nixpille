{ pkgs, ... }:

{
  users.users.runner = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
