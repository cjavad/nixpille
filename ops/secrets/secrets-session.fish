set -g RUNTIME_DIR "/run/user/"(id -u)
set -g SOPS_DIR "$RUNTIME_DIR/sops"
set -g SECRETS_FILE "$HOME/.config/sops/secrets.yaml"
set -gx SOPS_AGE_KEY_FILE "$HOME/.config/sops/age/keys.txt"

function _tmpfile
    mktemp -p $RUNTIME_DIR "secrets-XXXXXX"
end

function _shred --argument-names path
    test -f $path && shred -u $path 2>/dev/null || rm -f $path
end

# --- Pinentry ---

function _pinentry --argument-names prompt
    set -l pin (command -v pinentry-qt || command -v pinentry-gnome3 || command -v pinentry)
    if test -n "$pin"
        printf '%s\n' "SETDESC $prompt" "SETPROMPT Password:" "GETPIN" | $pin 2>/dev/null | grep '^D ' | cut -d' ' -f2-
    else
        systemd-ask-password "$prompt:"
    end
end

# --- Keyring helpers ---

function _kr_get --argument-names service type
    secret-tool lookup service $service type $type 2>/dev/null
end

function _kr_set --argument-names service type label
    secret-tool store --label "$label" service $service type $type
end

function _kr_del --argument-names service type
    secret-tool clear service $service type $type 2>/dev/null
end

function _kr_list --argument-names service
    secret-tool search --all service $service 2>/dev/null | grep "^attribute.type" | cut -d= -f2 | tr -d ' '
end

# --- Age key ---

function age_key_get
    _kr_get sops age-key
end

function age_key_set
    _kr_set sops age-key "SOPS Age Key"
end

function age_key_export
    # Export from keyring to tmpfs (for systems with keyring)
    set -l key (age_key_get)
    if test -n "$key"
        mkdir -p $SOPS_DIR && chmod 700 $SOPS_DIR
        printf '%s' "$key" > $SOPS_DIR/keys.txt
        chmod 600 $SOPS_DIR/keys.txt
        set -gx SOPS_AGE_KEY_FILE "$SOPS_DIR/keys.txt"
    end
    test -f "$SOPS_AGE_KEY_FILE"
end

function age_key_import
    test -f "$HOME/.config/sops/age/keys.txt" || return 1
    cat "$HOME/.config/sops/age/keys.txt" | age_key_set
end

# --- Bitwarden session ---

function bw_session_get
    _kr_get bitwarden session
end

function bw_session_set --argument-names session
    printf '%s' "$session" | _kr_set bitwarden session "Bitwarden Session"
end

function bw_session_clear
    _kr_del bitwarden session
end

function bw_unlock --argument-names BW pass
    set -l session (bw_session_get)
    if test -n "$session"
        set -x BW_SESSION $session
        test (eval $BW status 2>/dev/null | jq -r '.status') = "unlocked" && echo $session && return 0
        bw_session_clear
    end

    set -l bw_status (eval $BW status | jq -r '.status')
    test "$bw_status" = "unauthenticated" && echo "Not logged in" >&2 && return 1

    # Use provided password or prompt for one
    if test -z "$pass"
        set pass (_pinentry "Bitwarden Master Password")
        test -z "$pass" && return 1
    end

    set -x BW_PASSWORD "$pass"
    set session (eval $BW unlock --raw --passwordenv BW_PASSWORD 2>/dev/null)
    set -e BW_PASSWORD

    test -z "$session" && echo "Unlock failed" >&2 && return 1
    bw_session_set $session
    echo $session
end
