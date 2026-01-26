{
  config,
  pkgs,
  lib,
  ...
}:

let
  home = config.home.homeDirectory;

  backupPaths = [
    "${home}/Dev"
    "${home}/Work"
    "${home}/Documents"
    "${home}/Pictures"
    "${home}/Videos"
    "${home}/Music"
    "${home}/Downloads"
  ];

  backupPathsStr = lib.concatStringsSep " " backupPaths;

  kopiaSnapshotScript = pkgs.writeScript "kopia-snapshot" ''
    #!${pkgs.fish}/bin/fish
    set hostname (hostname)
    exec ${pkgs.kopia}/bin/kopia snapshot create \
      --hostname $hostname \
      ${backupPathsStr}
  '';
in
{
  home.packages = [ pkgs.kopia ];

  home.file.".kopiaignore".text = ''
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
    *.iso
    *.dmg
    *.AppImage
  '';

  systemd.user.services.kopia-snapshot = {
    Unit.Description = "Kopia backup snapshot";
    Service = {
      Type = "oneshot";
      ExecStart = "${kopiaSnapshotScript}";
    };
  };

  systemd.user.timers.kopia-snapshot = {
    Unit.Description = "Daily kopia backup";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
