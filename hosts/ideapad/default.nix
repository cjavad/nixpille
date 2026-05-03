{
  imports = [
    ./hardware.nix
    ../common/global
    ../common/optional/hyprland.nix
    ../common/optional/greetd.nix
    ../common/optional/stylix.nix
    ../common/optional/audio.nix
    ../common/optional/bluetooth.nix
    ../common/optional/nvidia.nix
    ../common/optional/ollama.nix
    # ../common/optional/lanzaboote.nix  # TODO: fix rust-std build issue
    ../common/optional/podman.nix
    ../common/optional/github-token.nix
    ../common/optional/rustdesk.nix
    ../common/users/javad.nix
  ];

  # Host-specific nvidia prime config
  hardware.nvidia.prime = {
    offload.enable = true;
    offload.enableOffloadCmd = true;
    amdgpuBusId = "PCI:6:0:0"; # TODO: verify with lspci | grep -E 'VGA|3D'
    nvidiaBusId = "PCI:1:0:0"; # TODO: verify
  };

  # Shut the laptop down before the battery reaches a deep-discharge state.
  services.upower = {
    usePercentageForPolicy = true;
    percentageLow = 25;
    percentageCritical = 12;
    percentageAction = 7;
    criticalPowerAction = "PowerOff";
  };

  networking.hostName = "ideapad";
  system.stateVersion = "25.11";
}
