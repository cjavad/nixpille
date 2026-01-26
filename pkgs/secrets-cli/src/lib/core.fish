# Core utilities: logging, errors, result pattern
#
# Result pattern:
#   result_ok "value"  -> sets REPLY, returns 0
#   result_err "msg"   -> logs error, returns 1
#
# Logging levels: debug < info < warn < error

# Color codes (disabled with SECRETS_NO_COLOR=1)
set -g _C_RESET ""
set -g _C_RED ""
set -g _C_GREEN ""
set -g _C_YELLOW ""
set -g _C_BLUE ""
set -g _C_DIM ""
set -g _C_BOLD ""

function _init_colors
    if not set -q SECRETS_NO_COLOR; and isatty stderr
        set -g _C_RESET (printf '\033[0m')
        set -g _C_RED (printf '\033[31m')
        set -g _C_GREEN (printf '\033[32m')
        set -g _C_YELLOW (printf '\033[33m')
        set -g _C_BLUE (printf '\033[34m')
        set -g _C_DIM (printf '\033[2m')
        set -g _C_BOLD (printf '\033[1m')
    end
end

_init_colors

# Log level to numeric value
function _log_level_num -a level
    switch $level
        case debug
            echo 0
        case info
            echo 1
        case warn
            echo 2
        case error
            echo 3
        case '*'
            echo 1
    end
end

function _should_log -a level
    set -l current (string lower -- $SECRETS_LOG_LEVEL)
    test -z "$current" && set current info
    test (_log_level_num $level) -ge (_log_level_num $current)
end

function log_debug
    _should_log debug || return 0
    echo "$_C_DIM[debug]$_C_RESET $argv" >&2
end

function log_info
    _should_log info || return 0
    echo "$_C_BLUE[info]$_C_RESET $argv" >&2
end

function log_warn
    _should_log warn || return 0
    echo "$_C_YELLOW[warn]$_C_RESET $argv" >&2
end

function log_error
    _should_log error || return 0
    echo "$_C_RED[error]$_C_RESET $argv" >&2
end

function log_success -a msg
    _should_log info || return 0
    echo "$_C_GREEN[ok]$_C_RESET $msg" >&2
end

function log_fail -a msg
    _should_log error || return 0
    echo "$_C_RED[fail]$_C_RESET $msg" >&2
end

# Result pattern - for functions that return values
function result_ok
    set -g REPLY $argv
    return 0
end

function result_err -a msg
    log_error $msg
    set -g REPLY ""
    return 1
end

# Assertions
function assert_file -a path msg
    if not test -f "$path"
        set -q msg[1] || set msg "File not found: $path"
        result_err $msg
        return 1
    end
end

function assert_dir -a path msg
    if not test -d "$path"
        set -q msg[1] || set msg "Directory not found: $path"
        result_err $msg
        return 1
    end
end

function assert_command -a cmd msg
    if not command -q $cmd
        set -q msg[1] || set msg "Command not found: $cmd"
        result_err $msg
        return 1
    end
end

function assert_var -a var msg
    if not set -q $var; or test -z "$$var"
        set -q msg[1] || set msg "Variable not set: $var"
        result_err $msg
        return 1
    end
end

# Fatal error - exit with message
function die
    log_error $argv
    exit 1
end

# Print section header
function section -a title
    echo ""
    echo "$_C_BOLD=== $title ===$_C_RESET"
end

# Print item with status
function item_ok -a name detail
    if test -n "$detail"
        echo "  $_C_GREEN+$_C_RESET $name $_C_DIM($detail)$_C_RESET"
    else
        echo "  $_C_GREEN+$_C_RESET $name"
    end
end

function item_fail -a name detail
    if test -n "$detail"
        echo "  $_C_RED-$_C_RESET $name $_C_DIM($detail)$_C_RESET"
    else
        echo "  $_C_RED-$_C_RESET $name"
    end
end

function item_skip -a name detail
    if test -n "$detail"
        echo "  $_C_DIM~$_C_RESET $name $_C_DIM($detail)$_C_RESET"
    else
        echo "  $_C_DIM~$_C_RESET $name"
    end
end
