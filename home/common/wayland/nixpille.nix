# Unified custom shell for nixpille (the Rust binary at ../nixpille-shell).
# Drops `np` + per-subcommand symlinks into PATH, generates the binary's
# config.toml from the existing `custom.monitors` data, and runs `np shelld`
# as a systemd user service.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.custom.nixpille;
  monitorsCfg = config.custom.monitors;

  nixpille = inputs.nixpille-shell.packages.${pkgs.stdenv.hostPlatform.system}.nixpille;

  # --- Translate the existing `custom.monitors` shape into the flat
  # per-connector form `nixpille monitors` consumes. We piggy-back on the
  # logic that monitors.nix already implements (alias → connector | desc:,
  # left-to-right x-position, group overrides) so there's exactly one
  # source of truth for layout.

  ceil =
    x:
    let
      s = builtins.toJSON x;
      parts = lib.splitString "." s;
      intPart = lib.toInt (builtins.head parts);
    in
    if builtins.length parts <= 1 then
      intPart
    else if builtins.match "0+" (builtins.elemAt parts 1) != null then
      intPart
    else
      intPart + 1;

  monitorCriteria =
    mon: if mon.connector != null then mon.connector else "desc:${mon.edid}";

  effectiveWidth = mon: ceil (mon.width * 1.0 / mon.scale);

  mkGroupEntries =
    group:
    let
      go =
        names: x:
        if names == [ ] then
          [ ]
        else
          let
            name = builtins.head names;
            rest = builtins.tail names;
            base = monitorsCfg.monitors.${name};
            mon = base // (group.overrides.${name} or { });
            ew = effectiveWidth mon;
          in
          [ { inherit name mon x; } ] ++ go rest (x + ew);
    in
    go group.monitors 0;

  groupToToml =
    _name: group:
    let
      entries = mkGroupEntries group;
      enabled = lib.listToAttrs (
        map (e: {
          name = monitorCriteria e.mon;
          value =
            {
              mode = "${toString e.mon.width}x${toString e.mon.height}@${builtins.toJSON e.mon.refreshRate}";
              scale = e.mon.scale;
              position = "${toString e.x}x0";
            }
            // lib.optionalAttrs (group.workspaces ? ${e.name}) {
              workspaces = [ group.workspaces.${e.name} ];
            };
        }) entries
      );
      # Disable every aliased output that's not in this group, so switching
      # cleans up outputs that were enabled by a previous group.
      disabledMons = lib.filterAttrs (n: _: !builtins.elem n group.monitors) monitorsCfg.monitors;
      disabled = lib.mapAttrs' (_: mon: {
        name = monitorCriteria mon;
        value = { disabled = true; };
      }) disabledMons;
    in
    enabled // disabled;

  configAttr =
    {
      monitors =
        {
          groups = lib.mapAttrs groupToToml monitorsCfg.groups;
          confirm_timeout_secs = cfg.confirmTimeoutSecs;
        }
        // lib.optionalAttrs (monitorsCfg.defaultGroup != "") {
          default = monitorsCfg.defaultGroup;
        };
    }
    // lib.optionalAttrs (cfg.battery.lowThreshold != null || cfg.battery.criticalThreshold != null) {
      battery = lib.filterAttrs (_: v: v != null) {
        low_threshold = cfg.battery.lowThreshold;
        critical_threshold = cfg.battery.criticalThreshold;
      };
    };

  configFile = (pkgs.formats.toml { }).generate "nixpille-config.toml" configAttr;
in
{
  options.custom.nixpille = {
    enable = lib.mkEnableOption "the nixpille unified custom-shell binary";

    enableShelld = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run `nixpille shelld` as a systemd user service. Owns the Hyprland
        socket2 event loop, exposes `com.nixpille.Shell1`, and applies the
        default monitor group on startup.
      '';
    };

    confirmTimeoutSecs = lib.mkOption {
      type = lib.types.int;
      default = 15;
      description = "Default `nixpille monitors switch` rollback timeout.";
    };

    aliases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "np"
        "monitors"
        "greeter"
        "locker"
        "shelld"
      ];
      description = ''
        argv[0] symlinks dropped into ~/.local/bin pointing at the nixpille
        binary. `np` is the short top-level alias; the rest hit the matching
        subcommand directly via argv[0] dispatch.
      '';
    };

    battery = {
      lowThreshold = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
      };
      criticalThreshold = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ nixpille ];

    home.file = lib.listToAttrs (
      map (n: {
        name = ".local/bin/${n}";
        value.source = "${nixpille}/bin/nixpille";
      }) cfg.aliases
    );

    xdg.configFile."nixpille/config.toml".source = configFile;

    systemd.user.services.nixpille-shelld = lib.mkIf cfg.enableShelld {
      Unit = {
        Description = "nixpille shelld — Hyprland event bridge + com.nixpille.Shell1";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${nixpille}/bin/nixpille shelld";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
