{ ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  zramSwap.enable = true;
  services.tlp.enable = true;
  services.fwupd.enable = true;
  services.libinput.enable = true;

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
