{ pkgs, ... }:

{
  # GitHub CLI for authentication and repo operations
  # Token for nix is provisioned via sops-nix at system level
  home.packages = [ pkgs.gh ];
}
