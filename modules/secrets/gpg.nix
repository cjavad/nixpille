# Deploy GPG keys from sops
{
  config,
  pkgs,
  lib,
  primaryUser,
  ...
}:

let
  home = config.users.users.${primaryUser}.home;

  mkGpgSecret = {
    owner = primaryUser;
    group = "users";
    mode = "0600";
  };
in
{
  sops.secrets = {
    gpg_key_personal = mkGpgSecret;
    gpg_key_hotmail = mkGpgSecret;
    gpg_key_simplyprint = mkGpgSecret;
  };

  system.activationScripts.gpgImport = lib.stringAfter [ "users" "setupSecrets" ] ''
    mkdir -p ${home}/.gnupg
    chown ${primaryUser}:users ${home}/.gnupg
    chmod 700 ${home}/.gnupg

    for key in gpg_key_personal gpg_key_hotmail gpg_key_simplyprint; do
      if [ -f "/run/secrets/$key" ]; then
        ${pkgs.su}/bin/su ${primaryUser} -c "${pkgs.gnupg}/bin/gpg --batch --import /run/secrets/$key" 2>/dev/null || true
      fi
    done
  '';
}
