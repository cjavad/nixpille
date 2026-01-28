# Kanshi - dynamic monitor configuration
# Scripts in ops/monitors/, use `task monitors:*` commands
{ pkgs, config, ... }:

{
  home.packages = [
    pkgs.kanshi
    pkgs.wlr-randr
  ];

  # Kanshi service
  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";

    settings = [
      {
        profile.name = "work-docked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "disable";
          }
          {
            criteria = "Dell Inc. DELL P2314H J8J3146IBZ8B";
            mode = "1920x1080@60Hz";
            position = "0,0";
            scale = 1.25;
          }
          {
            criteria = "Dell Inc. DELL P2414H 36WJX37G044L";
            mode = "1920x1080@60Hz";
            position = "1536,0";
            scale = 1.25;
          }
          {
            criteria = "AOC 2460G4 GJXH9HA034303";
            mode = "1920x1080@60Hz";
            position = "3072,0";
            scale = 1.25;
          }
        ];
      }
      {
        profile.name = "laptop";
        profile.outputs = [
          {
            criteria = "eDP-1";
            mode = "3200x2000@120Hz";
            scale = 1.6;
          }
        ];
      }
    ];
  };

  # Auto-restart kanshi when config changes, and restart waybar after
  systemd.user.services.kanshi = {
    Unit.X-Restart-Triggers = [ "${config.xdg.configFile."kanshi/config".source}" ];
    Service.ExecStartPost = "${pkgs.writeShellScript "kanshi-post" ''
      sleep 2
      ${pkgs.systemd}/bin/systemctl --user restart waybar || true
    ''}";
  };
}
