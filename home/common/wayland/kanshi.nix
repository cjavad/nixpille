# Kanshi - dynamic monitor configuration
# Monitor definitions in ./monitors.nix
{
  pkgs,
  config,
  lib,
  ...
}:

let
  monitors = import ./monitors.nix;

  # Convert our monitor format to kanshi output format
  toKanshiOutput =
    output:
    {
      criteria = output.criteria;
      mode = output.mode;
      scale = output.scale;
    }
    // lib.optionalAttrs (output ? position) {
      position = output.position;
    };

  # Generate kanshi profile from our format
  toKanshiProfile = name: profile: {
    profile.name = name;
    profile.outputs =
      # Add disabled internal display if specified
      (lib.optional (profile.disableInternal or false) {
        criteria = "eDP-1";
        status = "disable";
      })
      ++
        # Add all outputs
        (map toKanshiOutput profile.outputs);
  };
in
{
  home.packages = [
    pkgs.kanshi
    pkgs.wlr-randr
  ];

  # Kanshi service
  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";
    settings = lib.mapAttrsToList toKanshiProfile monitors.profiles;
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
