# Pinentry integration for single password prompt
#
# Uses pinentry to get password once, caches it in memory/tmpfs
# for reuse between login and unlock operations.

# Password cache file (tmpfs)
set -g _PINENTRY_CACHE_FILE "$SECRETS_RUNTIME_DIR/.secrets-pw-cache"
set -g _PINENTRY_CACHE_TIME 0

function _pinentry_cache_valid
    # Check if cache exists and is within TTL
    test -f "$_PINENTRY_CACHE_FILE" || return 1
    test $SECRETS_PASSWORD_CACHE_TTL -eq 0 && return 1

    set -l now (date +%s)
    set -l age (math $now - $_PINENTRY_CACHE_TIME)
    test $age -lt $SECRETS_PASSWORD_CACHE_TTL
end

function _pinentry_cache_clear
    if test -f "$_PINENTRY_CACHE_FILE"
        shred -u "$_PINENTRY_CACHE_FILE" 2>/dev/null
        or rm -f "$_PINENTRY_CACHE_FILE"
    end
    set -g _PINENTRY_CACHE_TIME 0
end

function _pinentry_cache_set -a password
    # Write password to tmpfs with restricted permissions
    set -l dir (dirname "$_PINENTRY_CACHE_FILE")
    mkdir -p $dir 2>/dev/null
    chmod 700 $dir 2>/dev/null

    # Create with restrictive umask
    umask 077
    printf '%s' "$password" > "$_PINENTRY_CACHE_FILE"
    chmod 600 "$_PINENTRY_CACHE_FILE"
    set -g _PINENTRY_CACHE_TIME (date +%s)
end

function _pinentry_cache_get
    test -f "$_PINENTRY_CACHE_FILE" || return 1
    cat "$_PINENTRY_CACHE_FILE"
end

# Get password via pinentry
function pinentry_getpass -a prompt desc
    # Check cache first
    if _pinentry_cache_valid
        log_debug "Using cached password"
        _pinentry_cache_get
        return 0
    end

    set -q prompt[1] || set prompt "Enter your password"
    set -q desc[1] || set desc "Bitwarden master password"

    # Try pinentry
    if command -q $SECRETS_PINENTRY
        log_debug "Using $SECRETS_PINENTRY for password prompt"

        # Build pinentry command sequence
        set -l cmd "SETDESC $desc
SETPROMPT $prompt:
GETPIN
BYE"

        set -l result (echo $cmd | $SECRETS_PINENTRY 2>/dev/null)
        set -l password (echo $result | grep "^D " | sed 's/^D //')

        if test -n "$password"
            _pinentry_cache_set $password
            echo $password
            return 0
        end

        # Check if user cancelled
        echo $result | grep -q "^ERR" && return 1
    end

    # Fallback to read
    log_debug "Falling back to terminal password prompt"
    read -s -P "$prompt: " password
    echo "" >&2

    if test -n "$password"
        _pinentry_cache_set $password
        echo $password
        return 0
    end

    return 1
end

# Write password to file for --passwordfile option
function pinentry_to_file -a prompt desc
    set -l password (pinentry_getpass $prompt $desc)
    or return 1

    set -l pwfile "$SECRETS_RUNTIME_DIR/.secrets-bw-pw"
    mkdir -p (dirname $pwfile) 2>/dev/null
    umask 077
    printf '%s' "$password" > $pwfile
    chmod 600 $pwfile

    echo $pwfile
end

# Clear password from memory
function pinentry_clear
    _pinentry_cache_clear
    rm -f "$SECRETS_RUNTIME_DIR/.secrets-bw-pw" 2>/dev/null
    log_debug "Password cache cleared"
end
