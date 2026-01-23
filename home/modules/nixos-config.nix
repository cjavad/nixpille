# Deploys a copy of this repo to ~/.config/nixos-config
{ pkgs, lib, ... }:

let
  repoSource = ../..;
in
{
  home.activation.copyNixosConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config"
    if [ ! -d "$HOME/.config/nixos-config/.git" ]; then
      verboseEcho "Copying nixos-config to $HOME/.config/nixos-config"
      run rm -rf "$HOME/.config/nixos-config"
      run cp -r ${repoSource} "$HOME/.config/nixos-config"
      run chmod -R u+w "$HOME/.config/nixos-config"
      run ${pkgs.git}/bin/git -C "$HOME/.config/nixos-config" init
      run ${pkgs.git}/bin/git -C "$HOME/.config/nixos-config" add -A
      verboseEcho "nixos-config copied successfully"
    else
      verboseEcho "nixos-config already exists at $HOME/.config/nixos-config"
    fi
  '';
}
