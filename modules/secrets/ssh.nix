# Deploy SSH keys from sops
{
  config,
  lib,
  primaryUser,
  ...
}:

let
  user = config.users.users.${primaryUser};
  home = user.home;

  mkSshSecret = name: {
    owner = primaryUser;
    group = "users";
    mode = "0600";
    path = "${home}/.ssh/${name}";
  };
in
{
  sops.secrets = {
    ssh_id_ed25519 = mkSshSecret "id_ed25519";
    ssh_id_ed25519_3dpreview = mkSshSecret "id_ed25519_3dpreview";
    ssh_id_rsa = mkSshSecret "id_rsa";
    ssh_ad_rsa = mkSshSecret "ad_rsa";
    ssh_id_site_packages = mkSshSecret "id_site_packages";
    ssh_id_site_packages_ed25519 = mkSshSecret "id_site_packages_ed25519";
    ssh_mrserver = mkSshSecret "mrserver";
    ssh_config = mkSshSecret "config";
  };

  system.activationScripts.sshDirectory = lib.stringAfter [ "users" ] ''
    mkdir -p ${home}/.ssh
    chown ${primaryUser}:users ${home}/.ssh
    chmod 700 ${home}/.ssh
  '';
}
