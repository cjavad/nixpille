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
    # ../common/optional/lanzaboote.nix  # TODO: fix rust-std build issue
    ../common/optional/podman.nix
    ../common/optional/github-token.nix
    ../common/users/javad.nix
  ];

  # Host-specific nvidia prime config
  hardware.nvidia.prime = {
    offload.enable = true;
    offload.enableOffloadCmd = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  networking.hostName = "p1gen8";
  system.stateVersion = "25.11";
}
