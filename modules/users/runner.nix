# CI runner user for GitHub Actions
{ pkgs, ... }:

{
  users.users.runner = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
