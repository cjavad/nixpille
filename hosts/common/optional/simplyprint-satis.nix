{
  config,
  lib,
  inputs,
  ...
}:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age.keyFile = "/run/user/1000/sops/keys.txt";
    validateSopsFiles = false;

    secrets.sp_satis_ca = {
      path = "/etc/simplyprint/ca.pem";
      mode = "0444";
      owner = "root";
    };

    secrets.sp_satis_client_cert = {
      path = "/etc/simplyprint/client.pem";
      mode = "0444";
      owner = "root";
    };

    secrets.sp_satis_client_key = {
      path = "/etc/simplyprint/client.key";
      mode = "0440";
      owner = "javad";
    };
  };
}
