# Declarative monitor configuration for Hyprland
# Generates monitor lines, workspace bindings, and a runtime `monitors` CLI
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.monitors;

  # Ceiling function via toJSON string parsing (Nix lacks builtins.ceil)
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

  # Hyprland criteria string for a monitor
  monitorCriteria =
    mon: if mon.connector != null then mon.connector else "desc:${mon.edid}";

  # Effective width in logical pixels
  effectiveWidth = mon: ceil (mon.width * 1.0 / mon.scale);

  # Hyprland monitor line for a single entry
  mkMonitorLine =
    e:
    "${monitorCriteria e.mon},${toString e.mon.width}x${toString e.mon.height}@${toString e.mon.refreshRate}Hz,${toString e.x}x0,${builtins.toJSON e.mon.scale}";

  # Build ordered monitor entries with calculated x positions for any group
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
            base = cfg.monitors.${name};
            mon = base // (group.overrides.${name} or { });
            ew = effectiveWidth mon;
          in
          [ { inherit name mon x; } ] ++ go rest (x + ew);
    in
    go group.monitors 0;

  # --- Static config for defaultGroup ---
  defaultGroup = cfg.groups.${cfg.defaultGroup};
  defaultEntries = mkGroupEntries defaultGroup;

  monitorLines = map mkMonitorLine defaultEntries ++ [ ",preferred,auto,1" ];

  workspaceLines = lib.imap1 (
    i: e:
    let
      ws = defaultGroup.workspaces.${e.name} or i;
    in
    "${toString ws}, monitor:${monitorCriteria e.mon}, default:true"
  ) defaultEntries;

  # --- Runtime `monitors` CLI ---
  groupsJson = builtins.toJSON {
    default = cfg.defaultGroup;
    groups = lib.mapAttrs (
      _: group:
      let
        entries = mkGroupEntries group;
        disabledMons = lib.filterAttrs (n: _: !builtins.elem n group.monitors) cfg.monitors;
      in
      {
        enable = map mkMonitorLine entries;
        disable = lib.mapAttrsToList (
          _: mon: "${monitorCriteria mon},disable"
        ) disabledMons;
      }
    ) cfg.groups;
  };

  groupsJsonFile = pkgs.writeText "monitors-config.json" groupsJson;
  jq = "${pkgs.jq}/bin/jq";

  monitorsScript = pkgs.writeScriptBin "monitors" ''
    #!${pkgs.fish}/bin/fish

    set -g _cfg ${groupsJsonFile}
    set -g _jq ${jq}

    function _switch -a group
        if not $_jq -e --arg g $group '.groups[$g]' $_cfg >/dev/null 2>&1
            echo "Unknown group: $group"
            _groups
            return 1
        end
        for line in ($_jq -r --arg g $group '.groups[$g].enable[]' $_cfg)
            hyprctl keyword monitor "$line"
        end
        for line in ($_jq -r --arg g $group '.groups[$g].disable[]' $_cfg)
            hyprctl keyword monitor "$line"
        end
        echo "Switched to: $group"
    end

    function _status
        echo "Connected:"
        hyprctl monitors -j | $_jq -r '.[] | "  \(.name): \(.description) \(.width)x\(.height)@\(.refreshRate)Hz scale:\(.scale)"'
    end

    function _groups
        set -l default ($_jq -r '.default' $_cfg)
        echo "Groups:"
        for g in ($_jq -r '.groups | keys[]' $_cfg)
            if test $g = $default
                echo "  $g (default)"
            else
                echo "  $g"
            end
        end
    end

    switch $argv[1]
        case switch
            if test (count $argv) -lt 2
                echo "Usage: monitors switch <group>"
                _groups
                return 1
            end
            _switch $argv[2]
        case status
            _status
        case groups
            _groups
        case -h --help ""
            echo "Usage: monitors <command>"
            echo ""
            echo "Commands:"
            echo "  <group>   Switch to a monitor group"
            echo "  status    Show connected monitors"
            echo "  groups    List available groups"
        case '*'
            if $_jq -e --arg g $argv[1] '.groups[$g]' $_cfg >/dev/null 2>&1
                _switch $argv[1]
            else
                echo "Unknown command: $argv[1]"
                echo "Run: monitors --help"
                return 1
            end
    end
  '';

in
{
  options.custom.monitors = {
    monitors = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            connector = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Connector name (e.g. eDP-1)";
            };
            edid = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "EDID description string";
            };
            width = lib.mkOption {
              type = lib.types.int;
              description = "Horizontal resolution";
            };
            height = lib.mkOption {
              type = lib.types.int;
              description = "Vertical resolution";
            };
            refreshRate = lib.mkOption {
              type = lib.types.int;
              default = 60;
              description = "Refresh rate in Hz";
            };
            scale = lib.mkOption {
              type = lib.types.float;
              default = 1.0;
              description = "Scale factor";
            };
          };
        }
      );
      default = { };
    };

    groups = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            monitors = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Ordered monitor names (left-to-right)";
            };
            overrides = lib.mkOption {
              type = lib.types.attrsOf lib.types.attrs;
              default = { };
              description = "Per-monitor {scale, refreshRate} overrides";
            };
            workspaces = lib.mkOption {
              type = lib.types.attrsOf lib.types.int;
              default = { };
              description = "Per-monitor default workspace override";
            };
          };
        }
      );
      default = { };
    };

    defaultGroup = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Which group to generate config from";
    };
  };

  config = lib.mkIf (cfg.monitors != { }) {
    wayland.windowManager.hyprland.settings = {
      monitor = monitorLines;
      workspace = workspaceLines;
    };
    home.packages = [ monitorsScript ];
  };
}
