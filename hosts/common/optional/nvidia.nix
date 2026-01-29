{ config, lib, ... }:

{
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # Prime offload configured per-host in hardware.nix or host default.nix
  # Note: Don't set GBM_BACKEND/GLX_VENDOR_LIBRARY_NAME globally with offload -
  # those are only for NVIDIA-primary setups. Use `nvidia-offload` command instead.
}
