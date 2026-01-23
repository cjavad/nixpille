# Deploy kubeconfig from sops
{
  config,
  lib,
  primaryUser,
  ...
}:

let
  home = config.users.users.${primaryUser}.home;
in
{
  sops.secrets.kubeconfig = {
    owner = primaryUser;
    group = "users";
    mode = "0600";
    path = "${home}/.kube/config";
  };

  system.activationScripts.kubeDirectory = lib.stringAfter [ "users" ] ''
    mkdir -p ${home}/.kube
    chown ${primaryUser}:users ${home}/.kube
    chmod 700 ${home}/.kube
  '';
}
