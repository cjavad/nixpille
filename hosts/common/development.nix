# Development tools configuration (Docker, Wireguard, etc.)
{
  imports = [
    ../../modules/dev/docker.nix
    ../../modules/services/wireguard.nix
  ];
}
