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
    ../common/optional/fingerprint.nix
    ../common/optional/github-token.nix
    ../common/optional/android.nix
    ../common/optional/gaming.nix
    ../common/optional/pcscd.nix
    ../common/optional/printing.nix
    ../common/optional/rustdesk.nix
    ../common/optional/simplyprint-satis.nix
    ../common/users/javad.nix
  ];

  # Host-specific nvidia prime config
  hardware.nvidia.prime = {
    offload.enable = true;
    offload.enableOffloadCmd = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  # ThinkPad battery charge thresholds (extend battery lifespan)
  services.tlp.settings = {
    START_CHARGE_THRESH_BAT0 = 75;
    STOP_CHARGE_THRESH_BAT0 = 80;
  };

  # Match the desktop battery notifier thresholds so low power is visible
  # before the machine reaches a dangerous discharge level.
  services.upower = {
    usePercentageForPolicy = true;
    percentageLow = 25;
    percentageCritical = 12;
    percentageAction = 7;
    criticalPowerAction = "PowerOff";
  };

  networking.hostName = "p1gen8";
  system.stateVersion = "25.11";
}
