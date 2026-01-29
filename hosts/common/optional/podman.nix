{ pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune.enable = true;
  };

  # Use slirp4netns for rootless networking (pasta has kernel 6.x bugs)
  virtualisation.containers.containersConf.settings.network.default_rootless_network_cmd =
    "slirp4netns";

  environment.systemPackages = with pkgs; [
    podman-compose
    slirp4netns
  ];
}
