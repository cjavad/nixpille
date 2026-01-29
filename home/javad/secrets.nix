{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  home = config.home.homeDirectory;
  runtime = "/run/user/1000";
in
{
  imports = [
    ../../modules/home-manager/secrets
  ];

  # Enable secrets management
  services.secrets = {
    enable = true;
    runtimeDir = runtime;
    keyringService = "nixpille";
    gpgAgent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-qt;
      defaultCacheTtl = 3600;
      maxCacheTtl = 86400;
    };
  };

  home.packages = with pkgs; [
    sops
    age
  ];

  # sops-nix for rotatable secrets (API tokens etc)
  sops = {
    defaultSopsFile = ../../hosts/common/secrets/secrets.yaml;
    age.keyFile = "${runtime}/sops/keys.txt";
    validateSopsFiles = false;

    secrets = {
      github_token.path = "${runtime}/nix/github-token";
      kopia_url.path = "${runtime}/kopia/url";
      kopia_username.path = "${runtime}/kopia/username";
      kopia_password.path = "${runtime}/kopia/password";
      docker_ghcr_auth.path = "${runtime}/docker/ghcr-auth";
      docker_hub_auth.path = "${runtime}/docker/hub-auth";
    };
  };

  # Ensure sops-nix waits for age key export and doesn't block login on failure
  systemd.user.services.sops-nix = {
    Unit = {
      After = [ "secrets-unlock.service" ];
      Wants = [ "secrets-unlock.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    Install.WantedBy = lib.mkForce [ "default.target" ];
  };

  # Override sops-nix activation to not fail hard - just warn
  home.activation.sops-nix = lib.mkForce (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ -v VERBOSE ]]; then
        echo "Activating sops-nix (non-blocking)..."
      fi
      ${pkgs.systemd}/bin/systemctl --user start sops-nix.service || {
        echo "WARNING: sops-nix failed to decrypt secrets (age key may not be available yet)"
        echo "         Run 'systemctl --user start sops-nix' after unlocking secrets"
      }
    ''
  );

  # Create necessary directories
  home.activation.secretsDirs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    mkdir -p "${home}/.ssh" "${home}/.kube" "${home}/.gnupg"
    chmod 700 "${home}/.ssh" "${home}/.kube" "${home}/.gnupg"
    mkdir -p "${runtime}/nix" "${runtime}/kopia" "${runtime}/docker"
    chmod 700 "${runtime}/nix" "${runtime}/kopia" "${runtime}/docker"
  '';

  # SSH config - include hosts.conf (symlinked from secrets)
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "${home}/.ssh/hosts.conf" ];
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      identitiesOnly = false;
    };
  };
}
