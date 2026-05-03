{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    startWhenNeeded = false;
    drivers = [ pkgs.cups-filters ];
    allowFrom = [ "all" ];
    browsing = true;
    defaultShared = false;
    extraConf = ''
      DefaultAuthType None
    '';
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="0a5f", MODE="0666", GROUP="lp"
  '';

  users.groups.lp = { };
}
