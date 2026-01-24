{ pkgs, ... }:

{
  security = {
    polkit.enable = true;
    rtkit.enable = true;
    protectKernelImage = true;

    apparmor = {
      enable = true;
      packages = [ pkgs.apparmor-utils ];
    };

    sudo.enable = false;
    sudo-rs = {
      enable = true;
      execWheelOnly = true;
      extraConfig = ''
        Defaults !lecture
        Defaults timestamp_timeout=30
      '';
    };

    pam.services = {
      hyprlock = { };
      swaylock = { };
      login.enableGnomeKeyring = false;
      sddm.enableGnomeKeyring = false;
    };
  };

  networking.firewall.enable = true;

  services.gnome.gnome-keyring.enable = false;

  environment.systemPackages = with pkgs; [
    polkit_gnome
    hyprlock
  ];

  systemd.user.services.polkit-gnome-agent = {
    description = "Polkit GNOME Authentication Agent";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
