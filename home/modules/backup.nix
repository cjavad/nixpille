{
  config,
  pkgs,
  lib,
  ...
}:

let
  home = config.home.homeDirectory;

  # Include-only: back up user-created data, skip app-generated and nix-managed
  # NOTE: .ssh and .gnupg are NOT backed up here - they're managed via sops-nix
  backupPaths = [
    # Code & projects
    "${home}/Dev"
    "${home}/Work"

    # Standard XDG data folders
    "${home}/Documents"
    "${home}/Pictures"
    "${home}/Videos"
    "${home}/Music"
    "${home}/Downloads"
  ];

  backupPathsStr = lib.concatStringsSep " " backupPaths;

  # Wrapper script that sets hostname for this machine's snapshots
  kopiaSnapshotScript = pkgs.writeShellScript "kopia-snapshot" ''
    HOSTNAME=$(hostname)
    exec ${pkgs.kopia}/bin/kopia snapshot create \
      --hostname "$HOSTNAME" \
      ${backupPathsStr}
  '';
in
{
  home.packages = with pkgs; [ kopia ];

  # Global ignore patterns for kopia
  home.file.".kopiaignore".text = ''
    # Build artifacts
    **/node_modules/
    **/target/
    **/build/
    **/dist/
    **/.next/
    **/vendor/
    **/__pycache__/
    **/.venv/
    **/.idea/
    **/.vscode/
    **/result
    **/.direnv/

    # Large binaries
    *.iso
    *.dmg
    *.AppImage
  '';

  # Kopia snapshot service - uses hostname for per-host snapshots
  systemd.user.services.kopia-snapshot = {
    Unit.Description = "Kopia backup snapshot";
    Service = {
      Type = "oneshot";
      ExecStart = "${kopiaSnapshotScript}";
    };
  };

  # Daily backup timer
  systemd.user.timers.kopia-snapshot = {
    Unit.Description = "Daily kopia backup";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
