{ ... }:

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
    };
  };
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

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  # Set nocow on /home for better git/database performance
  # Note: only affects NEW files created after this is set
  system.activationScripts.btrfsNocow = ''
    if [ -d /home ] && which chattr >/dev/null 2>&1; then
      chattr +C /home 2>/dev/null || true
    fi
  '';
}
