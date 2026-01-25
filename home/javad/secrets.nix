{
  config,
  pkgs,
  lib,
  ...
}:

let
  manifest = import ../../ops/secrets/manifest.nix;
  home = config.home.homeDirectory;
  gpgSecretNames = map (n: "gpg_${n}") manifest.gpg;
in
{
  home.packages = [ pkgs.pinentry-curses ];

  sops = {
    defaultSopsFile = "${home}/.config/sops/secrets.yaml";
    age.keyFile = "${home}/.config/sops/age/keys.txt";
    validateSopsFiles = false;

    secrets =
      lib.genAttrs (map (n: "ssh_${n}") manifest.ssh) (key: {
        path = "${home}/.ssh/${lib.removePrefix "ssh_" key}";
      })
      // lib.genAttrs gpgSecretNames (_: { })
      // lib.genAttrs (map (n: "wg_${n}") manifest.wg) (key: {
        path = "${home}/.config/wireguard/${lib.removePrefix "wg_" key}.conf";
      })
      // {
        kubeconfig.path = "${home}/.kube/config";
      };
  };

  home.activation.secretsDirs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    mkdir -p "${home}/.ssh" "${home}/.kube" "${home}/.gnupg" "${home}/.config/wireguard"
    chmod 700 "${home}/.ssh" "${home}/.kube" "${home}/.gnupg" "${home}/.config/wireguard"
  '';

  home.activation.gpgImport = lib.hm.dag.entryAfter [ "sopsInstallSecrets" ] ''
    ${lib.concatMapStrings (name: ''
      if [ -f "${config.sops.secrets.${name}.path}" ]; then
        ${pkgs.gnupg}/bin/gpg --batch --import "${config.sops.secrets.${name}.path}" || true
      fi
    '') gpgSecretNames}
  '';
}
