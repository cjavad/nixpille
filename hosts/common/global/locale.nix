{ ... }:

{
  # Timezone and NTP
  time.timeZone = "Europe/Copenhagen";

  services.timesyncd = {
    enable = true;
    servers = [
      "0.dk.pool.ntp.org"
      "1.dk.pool.ntp.org"
      "2.dk.pool.ntp.org"
      "3.dk.pool.ntp.org"
    ];
    fallbackServers = [
      "0.europe.pool.ntp.org"
      "1.europe.pool.ntp.org"
    ];
  };

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  console.keyMap = "dk";
  services.xserver.xkb = {
    layout = "dk,us";
    variant = "nodeadkeys,"; # dk uses nodeadkeys, us uses default
    options = "grp:alt_shift_toggle,lv3:ralt_switch";
  };
}
