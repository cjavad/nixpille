{
  imports = [
    ./hardware.nix
    ../common/global
    ../common/optional/hyprland.nix
    ../common/optional/sddm.nix
    ../common/optional/stylix.nix
    ../common/optional/audio.nix
    ../common/optional/bluetooth.nix
    ../common/optional/nvidia.nix
    ../common/optional/lanzaboote.nix
    ../common/optional/podman.nix
    ../common/optional/github-token.nix
    ../common/users/javad.nix
  ];

  # Host-specific nvidia prime config
  hardware.nvidia.prime = {
    offload.enable = true;
    offload.enableOffloadCmd = true;
    amdgpuBusId = "PCI:6:0:0"; # TODO: verify with lspci | grep -E 'VGA|3D'
    nvidiaBusId = "PCI:1:0:0"; # TODO: verify
  };

  networking.hostName = "ideapad";
  system.stateVersion = "25.11";
}
