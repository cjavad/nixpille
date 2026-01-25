{ pkgs, lib, ... }:

let
  repoSource = ../../..;
in
{
  home.activation.copyNixosConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/Dev/nixpille/.git" ]; then
      verboseEcho "Copying nixpille to $HOME/Dev/nixpille"
      run mkdir -p "$HOME/Dev"
      run rm -rf "$HOME/Dev/nixpille"
      run cp -r ${repoSource} "$HOME/Dev/nixpille"
      run chmod -R u+w "$HOME/Dev/nixpille"
      run ${pkgs.git}/bin/git -C "$HOME/Dev/nixpille" init
      run ${pkgs.git}/bin/git -C "$HOME/Dev/nixpille" add -A
      verboseEcho "nixpille copied successfully"
    else
      verboseEcho "nixpille already exists at $HOME/Dev/nixpille"
    fi
  '';
}
