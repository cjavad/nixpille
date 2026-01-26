# Secrets foundation - keyring setup and secrets export
#
# SSH/GPG keys are now pulled from Bitwarden via:
#   task secrets:pull
#
# This module handles:
# - GNOME Keyring for age key + file storage
# - Age key export to tmpfs for sops-nix
# - Files export from keyring to tmpfs (hosts.conf, kubeconfig, etc.)
# - sops-nix decrypts rotatable secrets (github_token)
{
  config,
  pkgs,
  lib,
  ...
}:

let
  runtime = "/run/user/1000";
  secretTool = "${pkgs.libsecret}/bin/secret-tool";
  jq = "${pkgs.jq}/bin/jq";

  # Export age key + files from keyring to tmpfs
  unlockScript = pkgs.writers.writeFish "secrets-unlock" ''
    set -l SOPS_DIR ${runtime}/sops
    set -l FILES_SERVICE nixpille

    function expand_path -a path
        set path (string replace -a '$HOME' $HOME $path)
        set path (string replace -a '$UID' (id -u) $path)
        set path (string replace -a '$XDG_RUNTIME_DIR' ${runtime} $path)
        echo $path
    end

    # Wait for keyring (up to 30s)
    set -l keyring_ready false
    for i in (seq 1 30)
      if ${secretTool} lookup service sops type age-key 2>/dev/null | read -l key
        set keyring_ready true
        break
      end
      sleep 1
    end

    if not $keyring_ready
      echo "Keyring not ready after 30s"
      exit 1
    end

    # Export age key
    set -l age_key (${secretTool} lookup service sops type age-key 2>/dev/null)
    if test -n "$age_key"
      mkdir -p $SOPS_DIR
      chmod 700 $SOPS_DIR
      printf '%s' "$age_key" > $SOPS_DIR/keys.txt
      chmod 600 $SOPS_DIR/keys.txt
      echo "Age key → $SOPS_DIR/keys.txt"
    end

    # Export files from keyring
    set -l manifest (${secretTool} lookup service $FILES_SERVICE type _manifest 2>/dev/null)
    if test -z "$manifest"
      echo "No file manifest in keyring (run: task secrets:pull)"
      exit 0
    end

    for filename in (echo $manifest | ${jq} -r 'keys[]')
      set -l dest (echo $manifest | ${jq} -r --arg f "$filename" '.[$f]')
      set -l content (${secretTool} lookup service $FILES_SERVICE type $filename 2>/dev/null)

      if test -z "$content"
        echo "  $filename: not in keyring"
        continue
      end

      if test "$dest" = "keyring"
        # Age key already handled above via sops service
        echo "  $filename → keyring (sops)"
      else
        set -l target (expand_path $dest)
        mkdir -p (dirname $target)
        printf '%s' "$content" > $target
        chmod 600 $target
        echo "  $filename → $target"
      end
    end

    echo "Secrets exported"
  '';
in
{
  # GNOME Keyring for secrets
  services.gnome-keyring = {
    enable = true;
    components = [
      "secrets"
      "pkcs11"
    ];
  };

  # GPG agent with SSH support
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 3600;
    maxCacheTtl = 86400;
  };

  # Export age key from keyring to tmpfs (for sops-nix)
  systemd.user.services.secrets-unlock = {
    Unit = {
      Description = "Export age key from keyring to tmpfs";
      After = [ "gnome-keyring-daemon.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${unlockScript}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.packages = with pkgs; [
    libsecret
    bitwarden-cli
    seahorse
    pinentry-qt
  ];

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh";
    SOPS_AGE_KEY_FILE = "$XDG_RUNTIME_DIR/sops/keys.txt";
    KUBECONFIG = "$XDG_RUNTIME_DIR/kube/config";
  };
}
