{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ ./hardware.nix ];

  networking.hostName = "ideapad";

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      amdgpuBusId = "PCI:6:0:0"; # TODO: verify with lspci | grep -E 'VGA|3D'
      nvidiaBusId = "PCI:1:0:0"; # TODO: verify
    };
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  services.openssh.enable = true;

  system.stateVersion = "25.11";
}
