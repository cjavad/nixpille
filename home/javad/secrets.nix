{
  config,
  pkgs,
  lib,
  ...
}:

let
  manifest = import ../../ops/secrets/manifest.nix;
  home = config.home.homeDirectory;
  runtime = "/run/user/1000";
  # Filter out empty strings from manifest lists
  filterEmpty = list: builtins.filter (s: s != "") (if list == null then [] else list);
in
{
  home.packages = with pkgs; [ sops age ];

  sops = {
    defaultSopsFile = "${home}/.config/sops/secrets.yaml";
    age.keyFile = "${runtime}/sops/keys.txt";
    validateSopsFiles = false;

    secrets =
      lib.genAttrs (map (n: "ssh_${n}") (filterEmpty manifest.ssh)) (key: {
        path = "${runtime}/ssh-secrets/${lib.removePrefix "ssh_" key}";
      })
      // lib.genAttrs (map (n: "gpg_${n}") (filterEmpty manifest.gpg)) (key: {
        path = "${runtime}/gpg-secrets/${lib.removePrefix "gpg_" key}";
      })
      // lib.genAttrs (map (n: "wg_${n}") (filterEmpty manifest.wg)) (key: {
        path = "${runtime}/wireguard/${lib.removePrefix "wg_" key}.conf";
      })
      // { kubeconfig.path = "${runtime}/kube/config"; };
  };

  # Ensure sops-nix waits for age key to be exported from keyring
  systemd.user.services.sops-nix = {
    Unit = {
      After = [ "secrets-unlock.service" ];
      Requires = [ "secrets-unlock.service" ];
    };
  };

  home.activation.secretsDirs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    mkdir -p "${home}/.ssh" "${home}/.kube" "${home}/.gnupg"
    chmod 700 "${home}/.ssh" "${home}/.kube" "${home}/.gnupg"
  '';

  # SSH config - include user's custom hosts file
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "~/.ssh/hosts.conf" ];
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      identitiesOnly = false;
    };
  };
}
