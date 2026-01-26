{ pkgs, ... }:

{
  virtualisation.containers.storage.settings = {
    storage = {
      driver = "btrfs";
      graphroot = "/var/lib/containers/storage";
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
