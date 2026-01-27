# Bitwarden CLI operations
#
# Key fixes from original:
# - Session stored in keyring, survives shell restarts
# - Single password prompt via pinentry (no double prompt)
# - Item lookup by ID to handle duplicates ("More than one result" fix)
# - Proper error handling with logging

# === Session Management ===

function _bw_run
    # Run BW CLI command
    $BW_CMD $argv
end

function _bw_session_from_keyring
    # Try to restore session from keyring
    set -l session (keyring_get_bw_session)
    test -z "$session" && return 1

    set -gx BW_SESSION $session

    # Verify it's still valid
    if _bw_run unlock --check 2>/dev/null
        log_debug "Session restored from keyring"
        return 0
    end

    # Invalid session, clear it
    log_debug "Cached session invalid, clearing"
    keyring_delete_bw_session
    set -e BW_SESSION
    return 1
end

function _bw_session_to_keyring -a session
    keyring_store_bw_session $session
    set -gx BW_SESSION $session
    log_debug "Session saved to keyring"
end

function bw_get_status
    # Get BW status: unauthenticated, locked, unlocked
    _bw_run status 2>/dev/null | jq -r '.status // "unknown"'
end

function bw_session
    # Ensure we have a valid session. Returns 0 if ready, 1 otherwise.

    # Trust existing BW_SESSION
    if set -q BW_SESSION; and test -n "$BW_SESSION"
        if _bw_run unlock --check 2>/dev/null
            return 0
        end
        # Session invalid, continue to re-establish
        set -e BW_SESSION
    end

    # Try keyring
    if _bw_session_from_keyring
        return 0
    end

    # Need to unlock/login
    set -l bw_st (bw_get_status)
    log_debug "BW status: $bw_st"

    switch $bw_st
        case unlocked
            # Unlocked but no session - get one
            set -l session (_bw_run unlock --raw 2>/dev/null)
            if test -n "$session"
                _bw_session_to_keyring $session
                return 0
            end
            log_error "Failed to get session from unlocked vault"
            return 1

        case locked
            # Get password via pinentry
            set -l pwfile (pinentry_to_file "Master Password" "Bitwarden Unlock")
            or begin
                log_error "Password entry cancelled"
                return 1
            end

            set -l session (_bw_run unlock --passwordfile $pwfile --raw 2>&1)
            set -l unlock_status $status

            # Clean up password file
            runtime_shred_file $pwfile

            if test $unlock_status -eq 0 -a -n "$session"
                _bw_session_to_keyring $session
                log_success "Bitwarden unlocked"
                return 0
            end

            log_error "Unlock failed"
            return 1

        case unauthenticated
            log_error "Not logged in. Run: secrets login"
            return 1

        case '*'
            log_error "Unknown BW status: $bw_st"
            return 1
    end
end

function bw_login
    # Login and unlock Bitwarden
    set -l bw_st (bw_get_status)

    switch $bw_st
        case unlocked
            log_info "Already unlocked"
            # Ensure session is in keyring
            if not set -q BW_SESSION
                set -l session (_bw_run unlock --raw 2>/dev/null)
                test -n "$session" && _bw_session_to_keyring $session
            end
            return 0

        case locked
            # Just unlock
            return (bw_session)

        case unauthenticated
            # Need full login
            read -P "Bitwarden email: " email
            test -z "$email" && return 1

            # Get password once
            set -l pwfile (pinentry_to_file "Master Password" "Bitwarden Login")
            or begin
                log_error "Password entry cancelled"
                return 1
            end

            log_info "Logging in..."
            # Run login directly (not captured) to allow TTY for 2FA
            _bw_run login $email --passwordfile $pwfile
            set -l login_status $status

            if test $login_status -ne 0
                runtime_shred_file $pwfile
                log_error "Login failed"
                return 1
            end

            # After login, vault is locked - unlock with same password
            log_info "Unlocking..."
            set -l session (_bw_run unlock --passwordfile $pwfile --raw 2>&1)
            set -l unlock_status $status

            runtime_shred_file $pwfile
            pinentry_clear

            if test $unlock_status -eq 0 -a -n "$session"
                _bw_session_to_keyring $session
                log_success "Logged in and unlocked"
                return 0
            end

            log_error "Unlock after login failed"
            return 1

        case '*'
            log_error "Unknown status: $bw_st"
            return 1
    end
end

function bw_lock
    # Lock vault and clear session
    _bw_run lock
    keyring_delete_bw_session
    set -e BW_SESSION
    pinentry_clear
    log_info "Bitwarden locked, session cleared"
end

function bw_sync
    bw_session || return 1
    _bw_run sync
end

# === Item Operations ===
# FIX: Use ID-based lookup to handle duplicates

function _bw_get_item_id -a name type
    # Get item ID by name and optional type
    # This handles the "More than one result" error
    bw_session || return 1

    set -l filter ".[] | select(.name == \"$name\")"
    if test -n "$type"
        set filter "$filter | select(.type == $type)"
    end
    set filter "$filter | .id"

    set -l ids (_bw_run list items 2>/dev/null | jq -r "$filter")

    if test (count $ids) -gt 1
        log_warn "Multiple items named '$name', using first"
    end

    echo $ids[1]
end

function bw_get_item -a name_or_id
    # Get item by name or ID
    # Returns full item JSON
    bw_session || return 1

    # First try as ID (UUID format)
    if string match -qr '^[0-9a-f-]{36}$' $name_or_id
        _bw_run get item $name_or_id 2>/dev/null
        return $status
    end

    # Otherwise lookup by name to get ID first
    set -l id (_bw_get_item_id $name_or_id)
    test -z "$id" && return 1

    _bw_run get item $id 2>/dev/null
end

function bw_get_notes -a name
    # Get notes field from secure note or login
    set -l item (bw_get_item $name)
    test -z "$item" && return 1
    echo $item | jq -r '.notes // .login.password // empty'
end

# FIX: Use jq -j to preserve exact content (no newline corruption)
function bw_get_notes_raw -a name
    # Get notes with exact content preservation
    set -l item (bw_get_item $name)
    test -z "$item" && return 1
    echo $item | jq -j '.notes // empty'
end

# === SSH Key Operations ===

function bw_list_ssh
    # List all SSH Key items (type 5)
    bw_session || return 1
    _bw_run list items 2>/dev/null | jq -r '.[] | select(.type == 5) | "\(.id)\t\(.name)"'
end

function bw_get_ssh -a id
    # Get SSH private key by item ID
    bw_session || return 1
    _bw_run get item $id 2>/dev/null | jq -r '.sshKey.privateKey // empty'
end

function bw_get_ssh_pub -a id
    # Get SSH public key by item ID
    bw_session || return 1
    _bw_run get item $id 2>/dev/null | jq -r '.sshKey.publicKey // empty'
end

function bw_create_ssh -a name privkey pubkey fingerprint
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

    echo $item | _bw_run encode | _bw_run create item
    _bw_run sync
end

# === Secure Note Operations ===

function bw_list_notes -a prefix
    # List secure notes, optionally filtered by prefix
    bw_session || return 1

    if test -n "$prefix"
        _bw_run list items 2>/dev/null | jq -r --arg p "$prefix" \
            '.[] | select(.type == 2) | select(.name | startswith($p)) | "\(.id)\t\(.name)"'
    else
        _bw_run list items 2>/dev/null | jq -r \
            '.[] | select(.type == 2) | "\(.id)\t\(.name)"'
    end
end

function bw_create_note -a name notes
    bw_session || return 1

    set -l item (jq -n \
        --arg name "$name" \
        --arg notes "$notes" \
        '{type: 2, name: $name, notes: $notes, secureNote: {type: 0}}')

    echo $item | _bw_run encode | _bw_run create item
    _bw_run sync
end

function bw_delete_item -a id
    bw_session || return 1
    _bw_run delete item $id
    _bw_run sync
end

# === Attachment Operations ===

function bw_get_attachment -a item_id filename output
    bw_session || return 1
    _bw_run get attachment "$filename" --itemid $item_id --output $output 2>/dev/null
end

function bw_create_attachment -a item_id filepath
    bw_session || return 1
    _bw_run create attachment --file $filepath --itemid $item_id
end

function bw_delete_attachment -a item_id att_id
    bw_session || return 1
    _bw_run delete attachment $att_id --itemid $item_id
end

# === Status ===

function bw_show_status
    echo -n "Bitwarden: "
    set -l bw_st (bw_get_status)

    switch $bw_st
        case unlocked
            if set -q BW_SESSION
                echo "unlocked (session active)"
            else if test -n (keyring_get_bw_session)
                echo "unlocked (session in keyring)"
            else
                echo "unlocked (no session cached)"
            end
        case locked
            echo "locked"
        case unauthenticated
            echo "not logged in"
        case '*'
            echo $bw_st
    end
end
