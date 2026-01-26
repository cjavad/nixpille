{
  config,
  pkgs,
  lib,
  ...
}:

let
  home = config.home.homeDirectory;
  runtime = "/run/user/1000";

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

  coreutils = "${pkgs.coreutils}/bin";

  # Connect to repository using secrets from sops
  kopiaConnectScript = pkgs.writeScript "kopia-connect" ''
    #!${pkgs.fish}/bin/fish
    set -l url (${coreutils}/cat ${runtime}/kopia/url)
    set -l user (${coreutils}/cat ${runtime}/kopia/username)
    set -l pass (${coreutils}/cat ${runtime}/kopia/password)

    # Check if already connected
    if ${pkgs.kopia}/bin/kopia repository status &>/dev/null
      exit 0
    end

    ${pkgs.kopia}/bin/kopia repository connect webdav \
      --url "$url" \
      --webdav-username "$user" \
      --webdav-password "$pass"
  '';

  kopiaSnapshotScript = pkgs.writeScript "kopia-snapshot" ''
    #!${pkgs.fish}/bin/fish
    set hostname (${pkgs.hostname}/bin/hostname)
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

  # Connect to kopia repository (runs after sops decrypts secrets)
  systemd.user.services.kopia-connect = {
    Unit = {
      Description = "Connect to Kopia repository";
      After = [ "sops-nix.service" ];
      Requires = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${kopiaConnectScript}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.kopia-snapshot = {
    Unit = {
      Description = "Kopia backup snapshot";
      After = [ "kopia-connect.service" ];
      Requires = [ "kopia-connect.service" ];
    };
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
