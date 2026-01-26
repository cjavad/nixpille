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
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.packages = with pkgs; [
    sops
    age
  ];

  sops = {
    # Only API tokens in sops (rotatable, safe in git)
    # Identity files (SSH, GPG) and configs (WG, kube, hosts) are in BW
    defaultSopsFile = ../../hosts/common/secrets/secrets.yaml;
    age.keyFile = "${runtime}/sops/keys.txt";
    validateSopsFiles = false;

    secrets = {
      github_token.path = "${runtime}/nix/github-token";
    };
  };

  # Ensure sops-nix waits for age key export
  systemd.user.services.sops-nix = {
    Unit = {
      After = [ "secrets-unlock.service" ];
      Requires = [ "secrets-unlock.service" ];
    };
  };

  home.activation.secretsDirs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    mkdir -p "${home}/.ssh" "${home}/.kube" "${home}/.gnupg"
    chmod 700 "${home}/.ssh" "${home}/.kube" "${home}/.gnupg"
    mkdir -p "${runtime}/nix"
    chmod 700 "${runtime}/nix"
  '';

  # SSH config - include hosts.conf from tmpfs (pulled from BW)
  programs.ssh = {
    enable = true;
    includes = [ "${runtime}/ssh/hosts.conf" ];
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      identitiesOnly = false;
    };
  };
}
