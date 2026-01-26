{ config, lib, ... }:

{
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # Prime offload configured per-host in hardware.nix or host default.nix
}
