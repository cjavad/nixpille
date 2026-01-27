# Secrets management module for home-manager
#
# Provides:
# - secrets-cli for Bitwarden + GNOME Keyring integration
# - Automatic export from keyring to tmpfs on login
# - GPG agent with SSH support
# - Environment variables for sops-nix integration
#
# Usage:
#   imports = [ nixpille.homeModules.secrets ];
#   services.secrets.enable = true;
#
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.secrets;

  # Derive runtime dir from UID if not specified
  defaultRuntimeDir =
    if config.home.uid != null then "/run/user/${toString config.home.uid}" else "/run/user/1000";

  runtime = cfg.runtimeDir;

  # Build secrets-cli package from pkgs source
  secrets-cli = pkgs.stdenvNoCC.mkDerivation {
    pname = "secrets-cli";
    version = "2.0.0";

    # Use the pkgs/secrets-cli/src as source (single source of truth)
    src = ../../../pkgs/secrets-cli/src;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
            runHook preInstall

            mkdir -p $out/share/secrets-cli
            cp -r . $out/share/secrets-cli/

            mkdir -p $out/bin
            cat > $out/bin/secrets << 'WRAPPER'
      #!/usr/bin/env fish
      set -gx SECRETS_LIB_DIR @out@/share/secrets-cli
      source $SECRETS_LIB_DIR/secrets $argv
      WRAPPER

            substituteInPlace $out/bin/secrets --replace-fail '@out@' "$out"
            chmod +x $out/bin/secrets

            wrapProgram $out/bin/secrets \
              --prefix PATH : ${
                lib.makeBinPath [
                  pkgs.fish
                  pkgs.bitwarden-cli
                  pkgs.libsecret
                  pkgs.jq
                  pkgs.coreutils
                  pkgs.gnupg
                  pkgs.openssh
                  pkgs.pinentry-qt
                  pkgs.findutils
                ]
              }

            runHook postInstall
    '';

    meta = with lib; {
      description = "Secrets management CLI via Bitwarden and GNOME Keyring";
      license = licenses.mit;
      platforms = platforms.linux;
      mainProgram = "secrets";
    };
  };

  secretTool = "${pkgs.libsecret}/bin/secret-tool";
  jq = "${pkgs.jq}/bin/jq";
  coreutils = "${pkgs.coreutils}/bin";

  # Export secrets from keyring to tmpfs + symlinks (runs on login)
  unlockScript = pkgs.writeShellScript "secrets-unlock" ''
    # Wait for runtime dir
    for i in $(seq 1 10); do
      [ -d "${runtime}" ] && break
      sleep 1
    done

    # Wait for keyring (up to 30s)
    for i in $(seq 1 30); do
      ${secretTool} lookup service ${cfg.keyringService} type _manifest >/dev/null 2>&1 && break
      sleep 1
    done

    # Run secrets export
    ${cfg.package}/bin/secrets export
  '';
in
{
  options.services.secrets = {
    enable = lib.mkEnableOption "secrets management via Bitwarden and GNOME Keyring";

    package = lib.mkOption {
      type = lib.types.package;
      default = secrets-cli;
      defaultText = lib.literalExpression "secrets-cli";
      description = "The secrets-cli package to use";
    };

    keyringService = lib.mkOption {
      type = lib.types.str;
      default = "nixpille";
      description = "Keyring service name for file storage";
    };

    runtimeDir = lib.mkOption {
      type = lib.types.str;
      default = defaultRuntimeDir;
      description = "XDG_RUNTIME_DIR path";
    };

    gnomeKeyring = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable GNOME Keyring for secrets storage";
      };
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

    unlockService = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic secrets export on login";
      };
    };

    sessionVariables = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Set environment variables for SSH_AUTH_SOCK, SOPS_AGE_KEY_FILE, KUBECONFIG";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # GNOME Keyring for secrets storage
    services.gnome-keyring = lib.mkIf cfg.gnomeKeyring.enable {
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
    systemd.user.services.secrets-unlock = lib.mkIf cfg.unlockService.enable {
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
      cfg.package
      pkgs.bitwarden-cli
      pkgs.libsecret
      pkgs.seahorse
    ];

    home.sessionVariables = lib.mkIf cfg.sessionVariables.enable {
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh";
      SOPS_AGE_KEY_FILE = "$XDG_RUNTIME_DIR/sops/keys.txt";
      KUBECONFIG = "$XDG_RUNTIME_DIR/kube/config";
    };
  };
}
