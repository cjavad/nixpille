{
  pkgs,
  lib,
  pkgs-unstable,
  config,
  inputs,
  ...
}:

let
  recorderScript = pkgs.writeScript "recorder" ''
    #!${pkgs.fish}/bin/fish
    if pgrep -x wf-recorder >/dev/null
      pkill -SIGINT wf-recorder
      notify-send "Recording stopped"
    else
      set area (slurp 2>/dev/null)
      test -z "$area"; and exit 0
      mkdir -p $HOME/Videos
      set file "$HOME/Videos/rec_"(date +%Y%m%d-%H%M%S)".mp4"
      if test "$argv[1]" = "-a"
        wf-recorder --audio -g "$area" -f "$file" &
      else
        wf-recorder -g "$area" -f "$file" &
      end
      notify-send "Recording started" "$file"
    end
  '';
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs-unstable.hyprland; # Match NixOS package
    systemd.enable = false; # Using UWSM

    settings = {
      # Monitor - scale can be overridden per-host
      monitor = [ ",preferred,auto,1.6" ];

      # Environment
      env = [
        "QT_QPA_PLATFORM,wayland"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "HYPRLAND_NO_SD_NOTIFY,1"
      ];

      # Input
      input = {
        kb_layout = "dk,us";
        kb_options = "grp:alt_shift_toggle";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
        };
        touchdevice = {
          enabled = true;
        };
      };

      # General - OLED-friendly (minimal borders)
      general = {
        gaps_in = 3;
        gaps_out = 6;
        border_size = 1;
        layout = "dwindle";
        "col.active_border" = lib.mkForce "rgba(89b4fa40)"; # Semi-transparent blue (OLED)
        "col.inactive_border" = lib.mkForce "rgba(00000000)"; # Fully transparent (OLED)
      };

      # Decoration - OLED-friendly (no blur/shadows for true blacks)
      decoration = {
        rounding = 6;
        blur.enabled = false;
        shadow.enabled = false;
      };

      # Animations
      animations = {
        enabled = true;
        bezier = [ "myBezier, 0.05, 0.9, 0.1, 1.05" ];
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Misc
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      # Disable update banner
      ecosystem = {
        no_update_news = true;
      };

      # Cursor
      cursor = {
        inactive_timeout = 5;
      };

      # Variables
      "$mainMod" = "ALT";
      "$secondaryMod" = "SUPER";

      # Keybindings
      bind = [
        # Terminal
        "$mainMod, Return, exec, kitty"
        "$secondaryMod, Return, exec, kitty"

        # Vicinae
        "$mainMod, space, exec, vicinae toggle"
        "$secondaryMod, space, exec, vicinae toggle"
        "CTRL ALT, space, exec, vicinae toggle"
        ", F12, exec, vicinae toggle"
        "$mainMod, C, exec, vicinae clipboard"
        "$secondaryMod, V, exec, vicinae clipboard"
        "$mainMod, E, exec, vicinae emoji"
        "$secondaryMod, period, exec, vicinae emoji"

        # Window management
        "$mainMod, Q, killactive,"
        "$mainMod SHIFT, E, exit,"
        "$mainMod, V, togglefloating,"
        "$mainMod, F, fullscreen,"
        "$mainMod, P, pseudo,"
        "$mainMod, S, togglesplit,"

        # Focus (arrows)
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Focus (vim)
        "$mainMod, H, movefocus, l"
        "$mainMod, L, movefocus, r"
        "$mainMod, K, movefocus, u"
        "$mainMod, J, movefocus, d"

        # Workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Screenshot submap
        ", Print, submap, screenshot"

        # Recording submap
        "$mainMod SHIFT, R, submap, recording"

        # Stop recording
        "$mainMod, Escape, exec, pkill -SIGINT wf-recorder"

        # Media
        ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"

        # Waybar toggle
        "$mainMod SHIFT, B, exec, pkill -SIGUSR1 waybar"

        # Lock
        "$secondaryMod, L, exec, hyprlock"

        # Idle inhibit
        "$mainMod SHIFT, I, exec, pkill -SIGUSR1 hypridle || hypridle"

        # Scratchpad
        "$mainMod, minus, togglespecialworkspace, scratchpad"
        "$mainMod SHIFT, minus, movetoworkspace, special:scratchpad"

        # Blue light filter
        "$mainMod SHIFT, N, exec, sunsetr toggle"
      ];

      # Repeat bindings (volume/brightness)
      binde = [
        ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
        ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
      ];

      # Release bindings
      bindr = [
        ", Caps_Lock, exec, swayosd-client --caps-lock"
      ];

      # Mouse bindings
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };

    # Submaps and window rules via extraConfig (Hyprland 0.53+ block syntax)
    extraConfig = ''
      # Window rules (Hyprland 0.53+ block syntax)
      windowrule {
        name = pavucontrol-float
        match:class = ^(pavucontrol|org\.pulseaudio\.pavucontrol)$
        float = on
        center = on
      }

      windowrule {
        name = nm-editor-float
        match:class = ^(nm-connection-editor)$
        float = on
        center = on
      }

      windowrule {
        name = vicinae-float
        match:class = ^(vicinae)$
        float = on
        center = on
        size = 800 600
      }

      windowrule {
        name = kitty-float
        match:class = ^(kitty-float)$
        float = on
        center = on
        size = 1000 700
      }

      windowrule {
        name = blueman-float
        match:class = ^(blueman-manager)$
        float = on
        center = on
      }

      # Screenshot submap
      submap = screenshot
      bind = , P, exec, grim -g "$(slurp)" - | swappy -f -
      bind = , P, submap, reset
      bind = , O, exec, grim - | swappy -f -
      bind = , O, submap, reset
      bind = SHIFT, P, exec, grim -g "$(slurp)" - | wl-copy
      bind = SHIFT, P, submap, reset
      bind = SHIFT, O, exec, grim - | wl-copy
      bind = SHIFT, O, submap, reset
      bind = , escape, submap, reset
      submap = reset

      # Recording submap
      submap = recording
      bind = , R, exec, ${recorderScript}
      bind = , R, submap, reset
      bind = SHIFT, R, exec, ${recorderScript} -a
      bind = SHIFT, R, submap, reset
      bind = , escape, submap, reset
      submap = reset
    '';
  };

  # Hyprlock config
  xdg.configFile."hypr/hyprlock.conf".text = ''
    general {
        disable_loading_bar = false
        hide_cursor = true
        grace = 0
    }

    background {
        monitor =
        color = rgba(0, 0, 0, 1.0)
    }

    label {
        monitor =
        text = $TIME
        color = rgba(205, 214, 244, 1.0)
        font_size = 90
        font_family = JetBrainsMono Nerd Font
        position = 0, 200
        halign = center
        valign = center
    }

    label {
        monitor =
        text = cmd[update:3600000] date +"%A, %d %B"
        color = rgba(205, 214, 244, 0.8)
        font_size = 24
        font_family = JetBrainsMono Nerd Font
        position = 0, 100
        halign = center
        valign = center
    }

    input-field {
        monitor =
        size = 300, 50
        outline_thickness = 2
        dots_size = 0.25
        dots_spacing = 0.15
        dots_center = true
        outer_color = rgba(137, 180, 250, 1.0)
        inner_color = rgba(0, 0, 0, 0.9)
        font_color = rgba(205, 214, 244, 1.0)
        fade_on_empty = false
        placeholder_text = <i>Password...</i>
        rounding = 12
        check_color = rgba(166, 227, 161, 1.0)
        fail_color = rgba(243, 139, 168, 1.0)
        fail_text = <i>$FAIL ($ATTEMPTS)</i>
        capslock_color = rgba(249, 226, 175, 1.0)
        position = 0, -120
        halign = center
        valign = center
    }
  '';

  # Hypridle config
  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
        lock_cmd = pidof hyprlock || hyprlock
        before_sleep_cmd = loginctl lock-session
        after_sleep_cmd = hyprctl dispatch dpms on
    }

    listener {
        timeout = 150
        on-timeout = brightnessctl -s set 30%
        on-resume = brightnessctl -r
    }

    listener {
        timeout = 300
        on-timeout = loginctl lock-session
    }

    listener {
        timeout = 330
        on-timeout = hyprctl dispatch dpms off
        on-resume = hyprctl dispatch dpms on
    }

    listener {
        timeout = 900
        on-timeout = systemctl suspend
    }
  '';

  # Systemd user services
  systemd.user.services = {
    hypridle = {
      Unit = {
        Description = "Hyprland idle daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.hypridle}/bin/hypridle";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    nm-applet = {
      Unit = {
        Description = "Network Manager applet";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    blueman-applet = {
      Unit = {
        Description = "Blueman applet";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.blueman}/bin/blueman-applet";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    sunsetr = {
      Unit = {
        Description = "Automatic blue light filter based on sunrise/sunset";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${inputs.sunsetr.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/sunsetr";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

  };

  # Sunsetr config (blue light filter with geolocation)
  xdg.configFile."sunsetr/config.toml".text = ''
    [general]
    backend = "hyprland"

    [location]
    latitude = 55.6761
    longitude = 12.5683

    [temperature]
    day = 6500
    night = 4000

    [transition]
    duration = 30

    [gamma]
    day = 1.0
    night = 0.85
  '';

  # Packages
  home.packages = with pkgs; [
    # Hyprland ecosystem
    hypridle
    hyprlock

    # Blue light filter
    inputs.sunsetr.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Screenshots & recording
    grim
    slurp
    swappy
    wf-recorder

    # Clipboard & audio
    wl-clipboard
    pamixer

    # Media
    playerctl

    # Tray
    networkmanagerapplet
    blueman

    # Utils
    jq
    libnotify
  ];
}
