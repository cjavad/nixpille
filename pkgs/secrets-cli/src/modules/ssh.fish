# SSH key management
#
# Architecture:
#   - BW sshKey items (type 5) are source of truth
#   - Keys cached in keyring for offline export
#   - Keys loaded into ssh-agent on pull/export
#
# Flow:
#   pull:   BW -> keyring -> ssh-agent
#   export: keyring -> ssh-agent (offline)

function _ssh_add_key -a name -a privkey
    # Add a key to ssh-agent from content
    set -l runtime (runtime_ensure ssh)

    # Normalize key format: BW stores keys with spaces instead of newlines
    # Fix: header\nbody\nfooter format
    set privkey (printf '%s' "$privkey" \
        | string replace -a \r '' \
        | string replace -r '(-----BEGIN [A-Z ]+ KEY-----) +' '$1\n' \
        | string replace -r ' +(-----END [A-Z ]+ KEY-----)' '\n$1' \
        | string collect)

    # Validate key format
    if not string match -q -- "-----BEGIN *PRIVATE KEY-----*" "$privkey"
        item_fail "$name" "invalid key format"
        return 1
    end

    # Write to tmpfs
    set -l keyfile "$runtime/$name"
    printf '%s\n' "$privkey" > "$keyfile"
    chmod 600 "$keyfile"

    # Add to agent
    set -l ssh_err (ssh-add "$keyfile" 2>&1)
    set -l ret $status

    # Keep key in tmpfs for IdentityFile usage (cleared on reboot)

    if test $ret -eq 0
        item_ok "$name" "loaded"
        return 0
    else
        if string match -q "*agent refused*" "$ssh_err"
            item_fail "$name" "agent refused"
        else if string match -q "*passphrase*" "$ssh_err"; or string match -q "*encrypted*" "$ssh_err"
            item_fail "$name" "encrypted (passphrase required)"
        else
            item_fail "$name" "$ssh_err"
        end
        return 1
    end
end

function ssh_pull
    # Pull SSH keys from BW -> keyring -> ssh-agent
    bw_session || return 1

    set -l keys (bw_list_ssh)
    if test -z "$keys"
        log_info "No SSH keys in Bitwarden"
        return 0
    end

    set -l loaded 0
    set -l failed 0

    for line in $keys
        set -l parts (string split \t -- "$line")
        if test (count $parts) -lt 2
            continue
        end
        set -l id $parts[1]
        set -l name $parts[2]

        # Get private key from BW
        set -l privkey (bw_get_ssh $id | string collect)
        if test -z "$privkey"
            item_fail "$name" "no private key"
            set failed (math $failed + 1)
            continue
        end

        # Store in keyring (key name IS the tracking mechanism)
        printf '%s' "$privkey" | keyring_store $SECRETS_KEYRING_SERVICE "ssh:$name" "SSH: $name"

        # Load into agent
        if _ssh_add_key "$name" "$privkey"
            set loaded (math $loaded + 1)
        else
            set failed (math $failed + 1)
        end
    end

    log_info "Loaded $loaded keys to agent"
    test $failed -gt 0 && log_warn "Failed: $failed"
end

function ssh_export
    # Export SSH keys from keyring -> ssh-agent (offline)
    set -l keys (keyring_list_prefix $SECRETS_KEYRING_SERVICE "ssh:")
    if test -z "$keys"
        log_info "No SSH keys in keyring (run 'secrets pull' first)"
        return 0
    end

    set -l loaded 0
    set -l failed 0

    for key in $keys
        set -l name (string replace "ssh:" "" $key)
        set -l privkey (keyring_get $SECRETS_KEYRING_SERVICE "$key")
        if test -z "$privkey"
            item_fail "$name" "not in keyring"
            set failed (math $failed + 1)
            continue
        end

        if _ssh_add_key "$name" "$privkey"
            set loaded (math $loaded + 1)
        else
            set failed (math $failed + 1)
        end
    end

    log_info "Loaded $loaded keys to agent (offline)"
    test $failed -gt 0 && log_warn "Failed: $failed"
end

function ssh_add -a keyfile
    # Add local SSH key to Bitwarden
    if test -z "$keyfile"
        echo "Usage: secrets ssh add <path_to_key>"
        echo "Example: secrets ssh add ~/.ssh/id_ed25519"
        return 1
    end

    set keyfile (eval echo "$keyfile")
    assert_file "$keyfile" "Key file not found: $keyfile" || return 1

    bw_session || return 1

    set -l name (basename "$keyfile")
    set -l privkey (cat "$keyfile" | string collect)
    set -l pubkey ""
    set -l fingerprint ""

    if test -f "$keyfile.pub"
        set pubkey (cat "$keyfile.pub" | string collect)
    else
        set pubkey (ssh-keygen -y -f "$keyfile" 2>/dev/null)
    end

    set fingerprint (ssh-keygen -lf "$keyfile" 2>/dev/null | awk '{print $2}')

    log_info "Adding: $name"
    bw_create_ssh "$name" "$privkey" "$pubkey" "$fingerprint"

    # Also store in keyring
    printf '%s' "$privkey" | keyring_store $SECRETS_KEYRING_SERVICE "ssh:$name" "SSH: $name"

    log_success "Added: $name"
end

function ssh_rm -a name
    # Remove SSH key from Bitwarden and keyring
    if test -z "$name"
        echo "Usage: secrets ssh rm <key_name>"
        return 1
    end

    bw_session || return 1

    # Get item
    set -l item (bw_get_item "$name")
    if test -z "$item"
        log_error "Not found: $name"
        return 1
    end

    set -l id (echo $item | jq -r '.id')
    bw_delete_item "$id"

    # Remove from keyring
    keyring_delete $SECRETS_KEYRING_SERVICE "ssh:$name"

    log_success "Removed: $name"
end

function ssh_list
    # List SSH keys from keyring
    echo "SSH keys:"
    set -l keys (keyring_list_prefix $SECRETS_KEYRING_SERVICE "ssh:")
    if test -z "$keys"
        echo "  (none in keyring - run 'secrets pull')"
        return 0
    end

    for key in $keys
        set -l name (string replace "ssh:" "" $key)
        echo "  $name"
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
