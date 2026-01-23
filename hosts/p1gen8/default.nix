{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ../../modules/users/javad.nix
  ];

  networking.hostName = "p1gen8";

  # Hybrid Intel + NVIDIA
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      # Bus IDs - verify with: lspci | grep -E 'VGA|3D'
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  services.fwupd.enable = true;
  services.tlp.enable = true;
  services.openssh.enable = true;
  networking.firewall.enable = true;

  system.stateVersion = "25.11";
}
