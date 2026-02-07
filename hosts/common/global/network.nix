{ ... }:

{
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPortRanges = [{ from = 7000; to = 7100; }]; # AirPlay (uxplay)
      allowedUDPPortRanges = [{ from = 6000; to = 7100; }]; # AirPlay (uxplay)
      allowedUDPPorts = [
        2021 # Bambu Lab SSDP discovery
        5353 # mDNS (Avahi)
      ];
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  systemd.services.NetworkManager-wait-online.enable = false;
}
