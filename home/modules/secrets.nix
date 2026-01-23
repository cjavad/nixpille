# User-level secrets management
{ pkgs, ... }:

{
  home.packages = [ pkgs.pinentry-curses ];
}
