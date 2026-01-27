# Bitwarden CLI operations

function _bw_run
    $BW_CMD $argv
end

function _bw_json -a json_input filter
    # Safe jq wrapper - returns empty on parse error
    if test -z "$json_input"
        return 1
    end
    printf '%s' "$json_input" | jq -r "$filter" 2>/dev/null
end

function _bw_session_from_keyring
    set -l session (keyring_get_bw_session)
    test -z "$session" && return 1
    set -gx BW_SESSION "$session"
    _bw_run unlock --check >/dev/null 2>&1 || begin
        keyring_delete_bw_session
        set -e BW_SESSION
        return 1
    end
    return 0
end

function _bw_session_to_keyring -a session
    printf '%s' "$session" | keyring_store_bw_session
    set -gx BW_SESSION "$session"
end

function bw_get_status
    set -l out (_bw_run status 2>/dev/null)
    _bw_json "$out" '.status // "unknown"'
end

function bw_session
    # Ensure valid session. Returns 0 if ready.
    # Check existing session
    if set -q BW_SESSION; and test -n "$BW_SESSION"
        _bw_run unlock --check >/dev/null 2>&1 && return 0
        set -e BW_SESSION
    end

    # Try keyring
    _bw_session_from_keyring && return 0

    # Need unlock
    set -l bw_st (bw_get_status)

    switch "$bw_st"
        case unlocked
            set -l session (_bw_run unlock --raw 2>/dev/null)
            if test -n "$session"
                _bw_session_to_keyring "$session"
                return 0
            end
            return 1

        case locked
            set -l pwfile (pinentry_to_file "Master Password" "Bitwarden Unlock")
            or return 1

            set -l session (_bw_run unlock --passwordfile "$pwfile" --raw 2>/dev/null)
            set -l ret $status
            runtime_shred_file "$pwfile"

            if test $ret -eq 0 -a -n "$session"
                _bw_session_to_keyring "$session"
                log_success "Unlocked"
                return 0
            end
            log_error "Unlock failed"
            return 1

        case unauthenticated
            log_error "Not logged in. Run: secrets login"
            return 1

        case '*'
            log_error "Unknown status: $bw_st"
            return 1
    end
end

function bw_login
    set -l bw_st (bw_get_status)

    switch "$bw_st"
        case unlocked
            if not set -q BW_SESSION
                set -l session (_bw_run unlock --raw 2>/dev/null)
                test -n "$session" && _bw_session_to_keyring "$session"
            end
            return 0

        case locked
            bw_session && return 0 || return 1

        case unauthenticated
            read -P "Bitwarden email: " email
            test -z "$email" && return 1

            set -l pwfile (pinentry_to_file "Master Password" "Bitwarden Login")
            or return 1

            _bw_run login "$email" --passwordfile "$pwfile"
            set -l login_ret $status

            if test $login_ret -ne 0
                runtime_shred_file "$pwfile"
                log_error "Login failed"
                return 1
            end

            set -l session (_bw_run unlock --passwordfile "$pwfile" --raw 2>/dev/null)
            set -l unlock_ret $status
            runtime_shred_file "$pwfile"
            pinentry_clear

            if test $unlock_ret -eq 0 -a -n "$session"
                _bw_session_to_keyring "$session"
                log_success "Logged in"
                return 0
            end
            log_error "Unlock failed"
            return 1

        case '*'
            log_error "Unknown status: $bw_st"
            return 1
    end
end

function bw_lock
    _bw_run lock >/dev/null 2>&1
    keyring_delete_bw_session
    set -e BW_SESSION
    pinentry_clear
end

function bw_sync
    # Sync local cache with server
    # Note: This may fail with "Unknown cipher type" if vault contains SSH keys (type 5)
    # but actual create/edit operations already succeeded on server, so we ignore errors
    bw_session || return 1
    _bw_run sync >/dev/null 2>&1 || true
end

# Item operations

function bw_get_item -a name_or_id
    # Get item by name or UUID
    # Uses 'bw get item' directly with search to avoid 'bw list items'
    # which fails when vault contains SSH keys (type 5)
    bw_session || return 1
    _bw_run get item "$name_or_id" 2>/dev/null | string collect
end

function bw_list_ssh
    # List ALL SSH keys (type 5) from vault
    bw_session || return 1
    set -l items (_bw_run list items 2>/dev/null)
    test -z "$items" && return 1
    _bw_json "$items" '.[] | select(.type == 5) | "\(.id)\t\(.name)"'
end

function bw_get_ssh -a id
    bw_session || return 1
    _bw_run get item "$id" 2>/dev/null | jq -r '.sshKey.privateKey // empty'
end

function bw_list_notes -a prefix
    # List secure notes - use search to avoid parsing all items
    bw_session || return 1

    if test -n "$prefix"
        set -l items (_bw_run list items --search "$prefix" 2>/dev/null)
        test -z "$items" && return 1
        echo "$items" | jq -r --arg p "$prefix" '.[] | select(.type == 2) | select(.name | startswith($p)) | "\(.id)\t\(.name)"' 2>/dev/null
    else
        # Without prefix, we can't safely list all - return empty
        log_warn "bw_list_notes requires a prefix to avoid listing all items"
        return 1
    end
end

function bw_create_ssh -a name -a privkey -a pubkey -a fingerprint
    bw_session || return 1
    set -l item (jq -n --arg name "$name" --arg priv "$privkey" --arg pub "$pubkey" --arg fp "$fingerprint" \
        '{type:5,name:$name,sshKey:{privateKey:$priv,publicKey:$pub,keyFingerprint:$fp}}' 2>/dev/null)
    test -z "$item" && return 1
    echo "$item" | _bw_run encode | _bw_run create item 2>/dev/null
    _bw_run sync 2>/dev/null
end

function bw_create_note -a name -a notes
    bw_session || return 1
    set -l item (jq -n --arg name "$name" --arg notes "$notes" \
        '{type:2,name:$name,notes:$notes,secureNote:{type:0}}' 2>/dev/null)
    test -z "$item" && return 1
    echo "$item" | _bw_run encode | _bw_run create item 2>/dev/null
    _bw_run sync 2>/dev/null
end

function bw_delete_item -a id
    bw_session || return 1
    _bw_run delete item "$id" 2>/dev/null
    _bw_run sync 2>/dev/null
end

function bw_get_attachment -a item_id -a filename -a output
    bw_session || return 1
    # Use --raw to avoid flatpak sandbox path issues
    _bw_run get attachment "$filename" --itemid "$item_id" --raw 2>/dev/null > "$output"
end

function bw_create_attachment -a item_id -a filepath
    bw_session || return 1
    _bw_run create attachment --file "$filepath" --itemid "$item_id"
end

function bw_delete_attachment -a item_id -a attachment_id
    bw_session || return 1
    _bw_run delete attachment "$attachment_id" --itemid "$item_id" 2>/dev/null
end

function bw_show_status
    set -l bw_st (bw_get_status)
    switch "$bw_st"
        case unlocked
            if set -q BW_SESSION
                echo "Bitwarden: unlocked (session active)"
            else if test -n (keyring_get_bw_session)
                echo "Bitwarden: unlocked (session cached)"
            else
                echo "Bitwarden: unlocked"
            end
        case locked
            echo "Bitwarden: locked"
        case unauthenticated
            echo "Bitwarden: not logged in"
        case '*'
            echo "Bitwarden: $bw_st"
    end
end
