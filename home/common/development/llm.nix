{ pkgs-unstable, pkgs-master, ... }:

{
  home.packages = [
    pkgs-master.claude-code
    pkgs-unstable.codex
  ];
}
