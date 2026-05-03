{ pkgs, ... }:

{
  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  zramSwap.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      # Platform profile (firmware-level power limits)
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # CPU governor on AC - performance mode
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Energy/performance preference
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      # Enable turbo boost on AC
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Intel HWP dynamic boost
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # Performance scaling range
      CPU_MIN_PERF_ON_AC = 50;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 80;

      # Intel GPU frequency (for iGPU)
      INTEL_GPU_MIN_FREQ_ON_AC = 300;
      INTEL_GPU_MAX_FREQ_ON_AC = 2300;
    };
  };

  services.upower.enable = true;
  services.fwupd.enable = true;

  # Thunderbolt device authorization (for docks)
  services.hardware.bolt.enable = true;
  services.libinput = {
    enable = true;
    touchpad.disableWhileTyping = false;
  };

  # Disable logind lid handling - Hyprland handles this with power-aware script
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

}
