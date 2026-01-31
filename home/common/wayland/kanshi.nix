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
    if (output.status or null) == "disable" then
      {
        criteria = output.criteria;
        status = "disable";
      }
    else
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
    profile.outputs = map toKanshiOutput profile.outputs;
  };

  # Internal display specs from monitors.nix
  internalOutput = lib.findFirst (o: o.criteria == "eDP-1") null (
    lib.concatMap (p: p.outputs) (lib.attrValues monitors.profiles)
  );
  internalRefresh = lib.last (lib.splitString "@" (lib.removeSuffix "Hz" internalOutput.mode));
  batteryRefresh = "60";

  # Battery variant of laptop profile (60Hz eDP-1)
  allProfiles = monitors.profiles // {
    laptop-battery = {
      outputs = map (
        o:
        if o.criteria == "eDP-1" && (o ? mode) then
          o // { mode = lib.replaceStrings [ "@${internalRefresh}" ] [ "@${batteryRefresh}" ] o.mode; }
        else
          o
      ) monitors.profiles.laptop.outputs;
    };
  };

  # AC-aware kanshi profile switcher
  acWatcher = pkgs.writeScript "ac-refresh-watcher" ''
    #!${pkgs.fish}/bin/fish

    function get_ac_state
      cat /sys/class/power_supply/AC*/online 2>/dev/null
      or cat /sys/class/power_supply/ACAD/online 2>/dev/null
      or echo "1"
    end

    function get_current_profile
      ${pkgs.kanshi}/bin/kanshictl status 2>/dev/null | ${pkgs.jq}/bin/jq -r '.current_profile // empty' 2>/dev/null
    end

    function apply_profile
      set ac (get_ac_state)
      set profile (get_current_profile)

      if test -z "$profile"
        return
      end

      # Only adjust when eDP-1 is active
      set edp_disabled (hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name == "eDP-1") | .disabled' 2>/dev/null)
      if test "$edp_disabled" != "false"
        return
      end

      # Determine base profile (strip -battery suffix if present)
      set base (string replace -r -- '-battery$' "" $profile)

      if test "$ac" = "0"
        set desired "$base-battery"
      else
        set desired "$base"
      end

      if test "$profile" != "$desired"
        ${pkgs.kanshi}/bin/kanshictl switch "$desired" 2>/dev/null
      end
    end

    # Initial apply after kanshi settles
    sleep 3
    apply_profile

    # React to AC/battery changes via upower
    ${pkgs.upower}/bin/upower --monitor | while read -l line
      if string match -q '*line-power*' $line
        sleep 2
        apply_profile
      end
    end
  '';
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
    settings = lib.mapAttrsToList toKanshiProfile allProfiles;
  };

  # Auto-restart kanshi when config changes, and restart waybar after
  systemd.user.services.kanshi = {
    Unit.X-Restart-Triggers = [ "${config.xdg.configFile."kanshi/config".source}" ];
    Service.ExecStartPost = "${pkgs.writeShellScript "kanshi-post" ''
      sleep 2
      ${pkgs.systemd}/bin/systemctl --user restart waybar || true
    ''}";
  };

  # AC-aware refresh rate watcher
  systemd.user.services.ac-refresh-watcher = {
    Unit = {
      Description = "Adjust eDP-1 refresh rate based on AC/battery state";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${acWatcher}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
