{
  config,
  pkgs,
  lib,
  ...
}:

let
  runtime = "/run/user/1000";

  unlockScript = pkgs.writers.writeFish "secrets-unlock" ''
    set -l SOPS_DIR ${runtime}/sops

    # Wait for keyring (up to 30s)
    for i in (seq 1 30)
      set -l key (${pkgs.libsecret}/bin/secret-tool lookup service sops type age-key 2>/dev/null)
      if test -n "$key"
        mkdir -p $SOPS_DIR
        chmod 700 $SOPS_DIR
        printf '%s' "$key" > $SOPS_DIR/keys.txt
        chmod 600 $SOPS_DIR/keys.txt
        echo "Age key exported"
        exit 0
      end
      sleep 1
    end
    echo "No age key in keyring"
  '';

  loaderScript = pkgs.writers.writeFish "secrets-loader" ''
    # SSH keys to agent
    for key in ${runtime}/ssh-secrets/*
      test -f $key || continue
      SSH_ASKPASS_REQUIRE=never ${pkgs.openssh}/bin/ssh-add $key 2>/dev/null
    end

    # GPG keys to keyring
    for key in ${runtime}/gpg-secrets/*
      test -f $key && ${pkgs.gnupg}/bin/gpg --batch --import $key 2>/dev/null
    end
    echo "Secrets loaded"
  '';
in
{
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" "pkcs11" ];
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 3600;
    maxCacheTtl = 86400;
  };

  # Stage 1: Export age key from keyring to tmpfs
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

  # Stage 2: Load SSH/GPG after sops-nix decrypts
  systemd.user.services.secrets-loader = {
    Unit = {
      Description = "Load secrets to SSH agent and GPG keyring";
      After = [ "sops-nix.service" ];
      Requires = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${loaderScript}";
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
