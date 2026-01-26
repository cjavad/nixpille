# Monitor management functions

function monitors_detect
    if command -q hyprctl && hyprctl monitors &>/dev/null
        echo "=== Connected Monitors ==="
        hyprctl monitors -j | jq -r '.[] | "  \(.name): \(.make) \(.model) \(.width)x\(.height)@\(.refreshRate)Hz"'
        echo ""
        echo "=== Kanshi Config Snippets ==="
        hyprctl monitors -j | jq -r '.[] | "output \"\(.make) \(.model) \(.serial)\" mode \(.width)x\(.height)@\(.refreshRate)Hz position \(.x),\(.y) scale \(.scale)"'
    else if command -q wlr-randr
        echo "=== wlr-randr ==="
        wlr-randr
    else
        echo "No Wayland compositor running"
        echo ""
        echo "=== DRM outputs ==="
        for f in /sys/class/drm/card*-*/status
            set -l card (dirname $f | xargs basename)
            set -l status (cat $f)
            echo "  $card: $status"
        end
    end
end

function monitors_reload
    if pgrep -x kanshi >/dev/null
        pkill kanshi
        sleep 0.2
    end
    kanshi &
    disown
    echo "Kanshi reloaded"
end

function monitors_edit
    set -l config ~/.config/kanshi/config
    mkdir -p (dirname $config)

    if not test -f $config
        echo "# Kanshi monitor profiles
# Run 'task monitors:detect' to get monitor names

profile laptop {
    output eDP-1 mode 2560x1600@60Hz scale 1.5
}

# profile docked {
#     output eDP-1 disable
#     output \"Dell Inc. DELL U2722D ABC123\" mode 2560x1440@60Hz position 0,0
# }
" > $config
    end

    $EDITOR $config
    echo ""
    echo "Run 'task monitors:reload' to apply changes"
end

function monitors_profiles
    set -l config ~/.config/kanshi/config
    if test -f $config
        echo "=== Kanshi Profiles ==="
        cat $config
    else
        echo "No kanshi config found"
        echo "Run 'task monitors:edit' to create one"
    end
end

function monitors_status
    echo "=== Kanshi Status ==="
    if pgrep -x kanshi >/dev/null
        echo "  Running: yes (pid "(pgrep -x kanshi)")"
    else
        echo "  Running: no"
    end

    set -l config ~/.config/kanshi/config
    if test -f $config
        set -l profiles (grep -c "^profile" $config)
        echo "  Config: $config ($profiles profiles)"
    else
        echo "  Config: not found"
    end
end
