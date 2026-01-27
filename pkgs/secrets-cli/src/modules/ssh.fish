# SSH key management
#
# BW sshKey items (type 5) -> ssh-agent
#
# FIX: Uses ID-based lookup to handle duplicate key names

function ssh_pull
    # Pull SSH keys from BW to ssh-agent
    bw_session || return 1

    set -l keys (bw_list_ssh)
    if test -z "$keys"
        log_info "No SSH keys in Bitwarden"
        return 0
    end

    set -l runtime (runtime_ensure ssh)
    set -l loaded 0
    set -l failed 0

    for line in $keys
        set -l parts (string split \t -- "$line")
        # Check we have both id and name
        if test (count $parts) -lt 2
            log_warn "Malformed entry: $line"
            continue
        end
        set -l id $parts[1]
        set -l name $parts[2]

        log_debug "Processing: $name ($id)"

        set -l privkey (bw_get_ssh $id)
        if test -z "$privkey"
            item_fail "$name" "no private key"
            set failed (math $failed + 1)
            continue
        end

        # Write to tmpfs temporarily
        set -l keyfile "$runtime/$name"
        printf '%s\n' "$privkey" > "$keyfile"
        chmod 600 "$keyfile"

        # Add to agent
        # Allow SSH_ASKPASS for encrypted keys (uses system askpass like ksshaskpass)
        set -l ssh_err (ssh-add "$keyfile" 2>&1)
        set -l add_ret $status
        if test $add_ret -eq 0
            item_ok "$name"
            set loaded (math $loaded + 1)
        else
            # Parse common ssh-add errors
            if string match -q "*agent refused*" "$ssh_err"
                item_fail "$name" "agent refused - is SSH_AUTH_SOCK set?"
            else if string match -q "*invalid format*" "$ssh_err"
                item_fail "$name" "invalid key format"
            else if string match -q "*passphrase*" "$ssh_err"; or string match -q "*encrypted*" "$ssh_err"
                item_fail "$name" "key is encrypted (passphrase required)"
            else if string match -q "*No such file*" "$ssh_err"
                item_fail "$name" "key file missing"
            else
                item_fail "$name" "ssh-add failed: $ssh_err"
            end
            set failed (math $failed + 1)
        end

        # Remove from tmpfs immediately
        runtime_shred_file "$keyfile"
    end

    # Clean up empty directory
    rmdir "$runtime" 2>/dev/null

    log_info "Loaded $loaded keys"
    if test $failed -gt 0
        log_warn "Failed: $failed"
    end
    return 0
end

function ssh_add -a keyfile
    # Add local SSH key to Bitwarden
    if test -z "$keyfile"
        echo "Usage: secrets ssh add <path_to_key>"
        echo "Example: secrets ssh add ~/.ssh/id_ed25519"
        return 1
    end

    # Expand path
    set keyfile (eval echo "$keyfile")
    assert_file "$keyfile" || return 1

    bw_session || return 1

    set -l name (basename "$keyfile")
    set -l privkey (cat "$keyfile")
    set -l pubkey ""
    set -l fingerprint ""

    # Get public key
    if test -f "$keyfile.pub"
        set pubkey (cat "$keyfile.pub")
    else
        set pubkey (ssh-keygen -y -f "$keyfile" 2>/dev/null)
    end

    # Get fingerprint
    set fingerprint (ssh-keygen -lf "$keyfile" 2>/dev/null | awk '{print $2}')

    log_info "Adding: $name"
    bw_create_ssh "$name" "$privkey" "$pubkey" "$fingerprint"
    log_success "Added: $name"
end

function ssh_rm -a name
    # Remove SSH key from Bitwarden
    if test -z "$name"
        echo "Usage: secrets ssh rm <key_name>"
        return 1
    end

    bw_session || return 1

    # Find by name
    set -l id (_bw_get_item_id "$name" 5)
    if test -z "$id"
        log_error "Not found: $name"
        return 1
    end

    bw_delete_item "$id"
    log_success "Removed: $name"
end

function ssh_list
    # List SSH keys in Bitwarden
    bw_session || return 1

    echo "SSH keys in Bitwarden:"
    set -l keys (bw_list_ssh)
    if test -z "$keys"
        echo "  (none)"
        return 0
    end

    for line in $keys
        set -l parts (string split \t -- "$line")
        if test (count $parts) -ge 2
            echo "  $parts[2]"
        end
    end
end

function ssh_status
    # Show SSH agent status
    echo "SSH Agent:"
    set -l keys (ssh-add -l 2>/dev/null)
    set -l ret $status
    if test $ret -ne 0
        echo "  (not running or empty)"
        return 0
    end

    for key in $keys
        echo "  $key"
    end
end
