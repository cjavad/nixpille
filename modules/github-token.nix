{
  config,
  lib,
  inputs,
  ...
}:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # Include GitHub token if available (avoids API rate limits)
  nix.extraOptions = ''
    !include /etc/nix/github-token.conf
  '';

  sops = {
    defaultSopsFile = ../hosts/common/secrets/secrets.yaml;
    age.keyFile = "/run/user/1000/sops/keys.txt";
    validateSopsFiles = false;

    secrets.github_token = {
      path = "/etc/nix/github-token.conf";
      mode = "0400";
      owner = "root";
    };
  };
}
