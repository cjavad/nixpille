# Core utilities: logging, errors
# No colors - just simple output

function _should_log -a level
    set -l current "$SECRETS_LOG_LEVEL"
    test -z "$current" && set current info

    switch $level
        case debug
            test "$current" = debug
        case info
            test "$current" = debug -o "$current" = info
        case warn
            test "$current" = debug -o "$current" = info -o "$current" = warn
        case error
            return 0
    end
end

function log_debug
    _should_log debug || return 0
    echo "[debug] $argv" >&2
end

function log_info
    _should_log info || return 0
    echo "[info] $argv" >&2
end

function log_warn
    _should_log warn || return 0
    echo "[warn] $argv" >&2
end

function log_error
    echo "[error] $argv" >&2
end

function log_success
    _should_log info || return 0
    echo "[ok] $argv" >&2
end

function log_fail
    echo "[fail] $argv" >&2
end

function die
    echo "[fatal] $argv" >&2
    exit 1
end

function section -a title
    echo ""
    echo "=== $title ==="
end

function item_ok -a name -a detail
    if test -n "$detail"
        echo "  + $name ($detail)"
    else
        echo "  + $name"
    end
end

function item_fail -a name -a detail
    if test -n "$detail"
        echo "  - $name ($detail)"
    else
        echo "  - $name"
    end
end

function item_skip -a name -a detail
    if test -n "$detail"
        echo "  ~ $name ($detail)"
    else
        echo "  ~ $name"
    end
end
