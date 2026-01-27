# GPG key management
#
# Architecture:
#   - BW secure notes (gpg-* prefix) store armored keys
#   - Keys cached in keyring for offline export
#   - Keys imported to GPG keyring on pull/export
#
# Flow:
#   pull:   BW -> keyring -> gpg keyring
#   export: keyring -> gpg keyring (offline)

function _gpg_import_key -a name -a armor
    # Import armored key to GPG keyring
    set -l runtime (runtime_ensure gpg-import)
    set -l keyfile "$runtime/"(string replace -a '/' '_' "$name")".asc"

    # Normalize key format: BW may store keys with spaces instead of newlines
    set armor (printf '%s' "$armor" \
        | string replace -a \r '' \
        | string replace -r '(-----BEGIN [A-Z ]+ BLOCK-----) +' '$1\n' \
        | string replace -r ' +(-----END [A-Z ]+ BLOCK-----)' '\n$1' \
        | string collect)

    printf '%s\n' "$armor" > "$keyfile"

    set -l gpg_err (gpg --batch --import "$keyfile" 2>&1)
    set -l ret $status

    runtime_shred_file "$keyfile"
    rmdir "$runtime" 2>/dev/null

    # Check if key was actually imported (gpg may return non-zero with warnings)
    if string match -q "*secret key imported*" "$gpg_err"
        item_ok "$name" "imported"
        return 0
    else if test $ret -eq 0
        item_ok "$name" "imported"
        return 0
    else
        set -l err_msg (printf '%s' "$gpg_err" | grep -i -E "error|failed" | grep -v "invalid armor" | head -1)
        test -z "$err_msg" && set err_msg "gpg exit $ret"
        item_fail "$name" "$err_msg"
        return 1
    end
end

function gpg_pull
    # Pull GPG keys from BW -> keyring -> gpg keyring
    bw_session || return 1

    set -l keys (bw_list_notes "$SECRETS_GPG_PREFIX")
    if test -z "$keys"
        log_info "No GPG keys in Bitwarden"
        return 0
    end

    set -l imported 0
    set -l failed 0

    for line in $keys
        set -l parts (string split \t -- "$line")
        if test (count $parts) -lt 2
            continue
        end
        set -l id $parts[1]
        set -l name $parts[2]

        # Get armored key from BW
        set -l item (bw_get_item "$id")
        if test -z "$item"
            item_fail "$name" "failed to get"
            set failed (math $failed + 1)
            continue
        end

        set -l armor (echo "$item" | jq -j '.notes // empty')
        if test -z "$armor"
            item_fail "$name" "no content"
            set failed (math $failed + 1)
            continue
        end

        # Store in keyring (key name IS the tracking mechanism)
        printf '%s' "$armor" | keyring_store $SECRETS_KEYRING_SERVICE "gpg:$name" "GPG: $name"

        # Import to GPG keyring
        if _gpg_import_key "$name" "$armor"
            set imported (math $imported + 1)
        else
            set failed (math $failed + 1)
        end
    end

    log_info "Imported $imported keys"
    test $failed -gt 0 && log_warn "Failed: $failed"
end

function gpg_export
    # Export GPG keys from keyring -> gpg keyring (offline)
    set -l keys (keyring_list_prefix $SECRETS_KEYRING_SERVICE "gpg:")
    if test -z "$keys"
        log_info "No GPG keys in keyring (run 'secrets pull' first)"
        return 0
    end

    set -l imported 0
    set -l failed 0

    for key in $keys
        set -l name (string replace "gpg:" "" $key)
        set -l armor (keyring_get $SECRETS_KEYRING_SERVICE "$key")
        if test -z "$armor"
            item_fail "$name" "not in keyring"
            set failed (math $failed + 1)
            continue
        end

        if _gpg_import_key "$name" "$armor"
            set imported (math $imported + 1)
        else
            set failed (math $failed + 1)
        end
    end

    log_info "Imported $imported keys (offline)"
    test $failed -gt 0 && log_warn "Failed: $failed"
end

function gpg_add -a keyid -a name
    # Export local GPG key to Bitwarden
    if test -z "$keyid"
        echo "Usage: secrets gpg add <keyid> [name]"
        echo "Example: secrets gpg add ABC123"
        return 1
    end

    bw_session || return 1

    set -l armor (gpg --export-secret-keys --armor "$keyid" 2>/dev/null)
    if test -z "$armor"
        log_error "Could not export key: $keyid"
        return 1
    end

    # Generate name if not provided
    if test -z "$name"
        set -l email (gpg --list-keys "$keyid" 2>/dev/null | grep uid | head -1 | string match -r '<(.+)>' | tail -1)
        if test -n "$email"
            set name "$SECRETS_GPG_PREFIX"(string replace -a '@' '-' (string replace -a '.' '-' "$email"))
        else
            set name "$SECRETS_GPG_PREFIX$keyid"
        end
    end

    # Ensure prefix
    if not string match -q "$SECRETS_GPG_PREFIX*" "$name"
        set name "$SECRETS_GPG_PREFIX$name"
    end

    log_info "Adding: $name"
    bw_create_note "$name" "$armor"

    # Also store in keyring
    printf '%s' "$armor" | keyring_store $SECRETS_KEYRING_SERVICE "gpg:$name" "GPG: $name"

    log_success "Added: $name"
end

function gpg_rm -a name
    # Remove GPG key from Bitwarden and keyring
    if test -z "$name"
        echo "Usage: secrets gpg rm <name>"
        return 1
    end

    bw_session || return 1

    set -l item (bw_get_item "$name")
    if test -z "$item"
        log_error "Not found: $name"
        return 1
    end

    set -l id (echo $item | jq -r '.id')
    bw_delete_item "$id"

    # Remove from keyring
    keyring_delete $SECRETS_KEYRING_SERVICE "gpg:$name"

    log_success "Removed: $name"
end

function gpg_list
    # List GPG keys from keyring
    echo "GPG keys:"
    set -l keys (keyring_list_prefix $SECRETS_KEYRING_SERVICE "gpg:")
    if test -z "$keys"
        echo "  (none in keyring - run 'secrets pull')"
        return 0
    end

    for key in $keys
        set -l name (string replace "gpg:" "" $key)
        echo "  $name"
    end
end

function gpg_status
    # Show local GPG keyring status
    echo "GPG Keyring (secret keys):"
    set -l keys (gpg --list-secret-keys --keyid-format SHORT 2>/dev/null)
    if test -z "$keys"
        echo "  (empty)"
        return 0
    end

    echo "$keys" | grep -E "^sec|^uid" | while read -l line
        echo "  $line"
    end
end
