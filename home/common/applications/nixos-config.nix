{ pkgs, lib, ... }:

let
  repoSource = ../..;
in
{
  home.activation.copyNixosConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Fallback: copy config repo if not bootstrapped by installer
    if [ ! -d "$HOME/Dev/nixpille" ]; then
      verboseEcho "Copying nixpille to $HOME/Dev/nixpille (fallback)"
      run mkdir -p "$HOME/Dev"
      run cp -a ${repoSource} "$HOME/Dev/nixpille"
      run chmod -R u+w "$HOME/Dev/nixpille"
      # Initialize git only if .git doesn't exist (nix store copy won't have it)
      if [ ! -d "$HOME/Dev/nixpille/.git" ]; then
        run ${pkgs.git}/bin/git -C "$HOME/Dev/nixpille" init
        run ${pkgs.git}/bin/git -C "$HOME/Dev/nixpille" add -A
      fi
      verboseEcho "nixpille copied successfully"
    fi

    # Fallback: ensure /etc/nixos symlink exists (systemd.tmpfiles should handle this,
    # but we ensure it here in case of manual install or recovery)
    if [ ! -L /etc/nixos ] || [ "$(readlink /etc/nixos)" != "$HOME/Dev/nixpille" ]; then
      verboseEcho "Creating /etc/nixos symlink"
      run sudo ln -sfn "$HOME/Dev/nixpille" /etc/nixos || true
    fi
  '';
}
