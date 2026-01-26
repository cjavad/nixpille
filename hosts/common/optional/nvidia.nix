{ config, lib, ... }:

{
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # NVIDIA Wayland environment variables
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # Prime offload configured per-host in hardware.nix or host default.nix
}
