# NixOS user definition for runner (CI/GHA)
{ pkgs, ... }:

{
  users.users.runner = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
