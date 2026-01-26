# Bitwarden CLI wrapper with keyring-based session management
#
# Session token stored in GNOME Keyring - survives shell restarts
# but cleared on logout/reboot (keyring locked)

source (dirname (status filename))/keyring.fish

# Use BW env var if set, otherwise find bw
# Split on spaces to handle commands like "flatpak run --command=bw ..."
if set -q BW
    set -g BW_CLI (string split ' ' $BW)
else
    set -g BW_CLI bw
end

function _bw_session_from_keyring
    # Try to restore session from keyring
    set -l session (keyring_get bitwarden session)
    if test -n "$session"
        set -gx BW_SESSION $session
        # Verify it's still valid
        if $BW_CLI unlock --check 2>/dev/null
            return 0
        end
        # Invalid session, clear it
        keyring_delete bitwarden session
        set -e BW_SESSION
    end
    return 1
end

function _bw_session_to_keyring -a session
    keyring_store bitwarden session "Bitwarden Session" "$session"
    set -gx BW_SESSION $session
end

function bw_session
    # Return 0 if we have a valid session, 1 otherwise

    # Trust BW_SESSION if set (user provided it)
    if set -q BW_SESSION
        return 0
    end

    # Try keyring
    if _bw_session_from_keyring
        return 0
    end

    # Need to unlock
    set -l bw_status ($BW_CLI status 2>/dev/null | jq -r '.status // "unknown"')

    switch $bw_status
        case unlocked
            # Weird state - unlocked but no session? Get one
            set -l session ($BW_CLI unlock --raw 2>/dev/null)
            if test -n "$session"
                _bw_session_to_keyring $session
                return 0
            end
            return 1

        case locked
            # Prompt for unlock
            set -l session ($BW_CLI unlock --raw)
            if test -n "$session"
                _bw_session_to_keyring $session
                return 0
            end
            echo "Unlock failed" >&2
            return 1

        case unauthenticated
            echo "Not logged in - run: task secrets:login" >&2
            return 1

        case '*'
            echo "Unknown BW status: $bw_status" >&2
            return 1
    end
end

function bw_login
    set -l bw_status ($BW_CLI status | jq -r '.status')

    switch $bw_status
        case unlocked
            echo "Already unlocked"
            # Make sure session is in keyring
            if not set -q BW_SESSION
                set -l session ($BW_CLI unlock --raw)
                test -n "$session" && _bw_session_to_keyring $session
            end
            return 0

        case unauthenticated
            read -P "Email: " email
            $BW_CLI login $email
            set -l login_status $status
            test $login_status -ne 0 && return 1

            # After login, vault is locked - unlock it
            set -l session ($BW_CLI unlock --raw)
            if test -n "$session"
                _bw_session_to_keyring $session
                echo "Logged in and unlocked (session stored in keyring)"
                return 0
            end
            return 1

        case locked
            set -l session ($BW_CLI unlock --raw)
            if test -n "$session"
                _bw_session_to_keyring $session
                echo "Unlocked (session stored in keyring)"
                return 0
            end
            return 1

        case '*'
            echo "Status: $bw_status"
            return 1
    end
end

function bw_sync
    bw_session || return 1
    $BW_CLI sync
end

function bw_get -a name
    # Get notes/password from secure note or login item
    bw_session || return 1
    $BW_CLI get item $name 2>/dev/null | jq -r '.notes // .login.password // empty'
end

function bw_get_ssh -a name
    # Get private key from SSH Key item (type 5)
    bw_session || return 1
    $BW_CLI get item $name 2>/dev/null | jq -r '.sshKey.privateKey // empty'
end

function bw_get_ssh_pub -a name
    # Get public key from SSH Key item (type 5)
    bw_session || return 1
    $BW_CLI get item $name 2>/dev/null | jq -r '.sshKey.publicKey // empty'
end

function bw_list_ssh
    # List all SSH Key items (type 5)
    bw_session || return 1
    $BW_CLI list items 2>/dev/null | jq -r '.[] | select(.type == 5) | .name'
end

function bw_list_notes -a prefix
    # List secure notes, optionally filtered by name prefix
    bw_session || return 1
    if test -n "$prefix"
        $BW_CLI list items 2>/dev/null | jq -r --arg p "$prefix" '.[] | select(.type == 2) | select(.name | startswith($p)) | .name'
    else
        $BW_CLI list items 2>/dev/null | jq -r '.[] | select(.type == 2) | .name'
    end
end

function bw_create_ssh -a name privkey pubkey fingerprint
    # Create SSH Key item (type 5)
    bw_session || return 1
    set -l item (jq -n \
        --arg name "$name" \
        --arg priv "$privkey" \
        --arg pub "$pubkey" \
        --arg fp "$fingerprint" \
        '{
          type: 5,
          name: $name,
          sshKey: {
            privateKey: $priv,
            publicKey: $pub,
            keyFingerprint: $fp
          }
        }')

    echo $item | $BW_CLI encode | $BW_CLI create item
    $BW_CLI sync
end

function bw_create_note -a name notes
    # Create Secure Note item (type 2)
    bw_session || return 1
    set -l item (jq -n \
        --arg name "$name" \
        --arg notes "$notes" \
        '{type: 2, name: $name, notes: $notes, secureNote: {type: 0}}')

    echo $item | $BW_CLI encode | $BW_CLI create item
    $BW_CLI sync
end

function bw_lock
    $BW_CLI lock
    keyring_delete bitwarden session
    set -e BW_SESSION
    echo "Bitwarden locked, session cleared from keyring"
end

function bw_status
    echo -n "Bitwarden: "
    if bw_session 2>/dev/null
        echo "unlocked (session in keyring)"
    else
        set -l st ($BW_CLI status 2>/dev/null | jq -r '.status // "unknown"')
        echo $st
    end
end
