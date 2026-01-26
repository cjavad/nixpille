# Secrets management module
#
# Uses secrets-cli for BW/keyring operations
# Provides:
# - GNOME Keyring for age key + file storage
# - Age key export to tmpfs for sops-nix
# - Files export from keyring to tmpfs
# - GPG agent with SSH support
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.secrets;
  runtime = cfg.runtimeDir;
  secretTool = "${pkgs.libsecret}/bin/secret-tool";
  jq = "${pkgs.jq}/bin/jq";
  coreutils = "${pkgs.coreutils}/bin";

  # Export age key + files from keyring to tmpfs (runs on login)
  unlockScript = pkgs.writers.writeFish "secrets-unlock" ''
    set -l SOPS_DIR ${runtime}/sops

    function expand_path -a path
      set path (string replace -a '$HOME' $HOME $path)
      set path (string replace -a '$UID' (${coreutils}/id -u) $path)
      set path (string replace -a '$XDG_RUNTIME_DIR' ${runtime} $path)
      echo $path
    end

    # Wait for runtime dir
    for i in (seq 1 10)
      test -d ${runtime} && break
      ${coreutils}/sleep 1
    end

    # Wait for keyring (up to 30s)
    set -l keyring_ready false
    for i in (seq 1 30)
      if ${secretTool} lookup service sops type age-key 2>/dev/null | read -l key
        set keyring_ready true
        break
      end
      ${coreutils}/sleep 1
    end

    if not $keyring_ready
      echo "Keyring not ready after 30s"
      exit 1
    end

    # Export age key
    set -l age_key (${secretTool} lookup service sops type age-key 2>/dev/null)
    if test -n "$age_key"
      ${coreutils}/mkdir -p $SOPS_DIR
      ${coreutils}/chmod 700 $SOPS_DIR
      printf '%s' "$age_key" > $SOPS_DIR/keys.txt
      ${coreutils}/chmod 600 $SOPS_DIR/keys.txt
      echo "Age key -> $SOPS_DIR/keys.txt"
    end

    # Export files from keyring
    set -l manifest (${secretTool} lookup service ${cfg.keyringService} type _manifest 2>/dev/null)
    if test -z "$manifest"
      echo "No file manifest in keyring (run: secrets pull)"
      exit 0
    end

    for filename in (echo $manifest | ${jq} -r 'keys[]')
      set -l dest (echo $manifest | ${jq} -r --arg f "$filename" '.[$f]')
      set -l content (${secretTool} lookup service ${cfg.keyringService} type $filename 2>/dev/null)

      if test -z "$content"
        echo "  $filename: not in keyring"
        continue
      end

      if test "$dest" = "keyring"
        echo "  $filename -> keyring (sops)"
      else
        set -l target (expand_path $dest)
        ${coreutils}/mkdir -p (${coreutils}/dirname $target)
        printf '%s' "$content" > $target
        ${coreutils}/chmod 600 $target
        echo "  $filename -> $target"
      end
    end

    echo "Secrets exported"
  '';
in
{
  options.services.secrets = {
    enable = lib.mkEnableOption "secrets management via Bitwarden and GNOME Keyring";

    keyringService = lib.mkOption {
      type = lib.types.str;
      default = "nixpille";
      description = "Keyring service name for file storage";
    };

    runtimeDir = lib.mkOption {
      type = lib.types.str;
      default = "/run/user/1000";
      description = "XDG_RUNTIME_DIR path";
    };

    gpgAgent = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable GPG agent with SSH support";
      };

      pinentryPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.pinentry-qt;
        description = "Pinentry package to use";
      };

      defaultCacheTtl = lib.mkOption {
        type = lib.types.int;
        default = 3600;
        description = "Default cache TTL in seconds";
      };

      maxCacheTtl = lib.mkOption {
        type = lib.types.int;
        default = 86400;
        description = "Maximum cache TTL in seconds";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # GNOME Keyring for secrets storage
    services.gnome-keyring = {
      enable = true;
      components = [
        "secrets"
        "pkcs11"
      ];
    };

    # GPG agent with SSH support
    services.gpg-agent = lib.mkIf cfg.gpgAgent.enable {
      enable = true;
      enableSshSupport = true;
      pinentry.package = cfg.gpgAgent.pinentryPackage;
      defaultCacheTtl = cfg.gpgAgent.defaultCacheTtl;
      maxCacheTtl = cfg.gpgAgent.maxCacheTtl;
    };

    # Export secrets from keyring on login
    systemd.user.services.secrets-unlock = {
      Unit = {
        Description = "Export secrets from keyring to tmpfs";
        After = [ "gnome-keyring-daemon.service" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${unlockScript}";
      };
      Install.WantedBy = [ "default.target" ];
    };

    home.packages = [
      pkgs.custom.secrets-cli
      pkgs.libsecret
      pkgs.seahorse
    ];

    home.sessionVariables = {
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh";
      SOPS_AGE_KEY_FILE = "$XDG_RUNTIME_DIR/sops/keys.txt";
      KUBECONFIG = "$XDG_RUNTIME_DIR/kube/config";
    };
  };
}
