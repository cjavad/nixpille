# GPG key management
#
# BW secure notes -> GPG keyring
#
# FIX: Uses jq -j for exact content preservation (no newline corruption)
# FIX: Imports from file instead of stdin (more reliable)

function gpg_pull
    # Pull GPG keys from BW to GPG keyring
    bw_session || return 1

    set -l keys (bw_list_notes $SECRETS_GPG_PREFIX)
    if test -z "$keys"
        log_info "No GPG keys in Bitwarden"
        return 0
    end

    set -l runtime (runtime_ensure gpg-import)
    set -l imported 0
    set -l failed 0

    for line in $keys
        set -l parts (string split \t $line)
        set -l id $parts[1]
        set -l name $parts[2]

        log_debug "Processing: $name ($id)"

        # Get item and extract notes with jq -j (preserves exact content)
        set -l item (bw_get_item $id)
        if test -z "$item"
            item_fail $name "failed to get item"
            set failed (math $failed + 1)
            continue
        end

        # FIX: Use jq -j to preserve exact armored key (no trailing newline corruption)
        set -l armor (echo $item | jq -j '.notes // empty')
        if test -z "$armor"
            item_fail $name "no notes content"
            set failed (math $failed + 1)
            continue
        end

        # FIX: Write to file first, then import from file
        # This is more reliable than piping through stdin
        set -l keyfile $runtime/(string replace -a '/' '_' $name).asc
        printf '%s' "$armor" > $keyfile

        # Import from file
        gpg --batch --import $keyfile 2>/dev/null
        if test $status -eq 0
            item_ok $name
            set imported (math $imported + 1)
        else
            item_fail $name "gpg import failed"
            set failed (math $failed + 1)
        end

        # Clean up
        runtime_shred_file $keyfile
    end

    rmdir $runtime 2>/dev/null

    log_info "Imported $imported keys"
    test $failed -gt 0 && log_warn "Failed: $failed"
    return 0
end

function gpg_add -a keyid name
    # Export local GPG key to Bitwarden
    if test -z "$keyid"
        echo "Usage: secrets gpg add <keyid> [name]"
        echo "Example: secrets gpg add ABC123"
        echo "Example: secrets gpg add ABC123 gpg-work"
        return 1
    end

    bw_session || return 1

    # Export armored secret key
    set -l armor (gpg --export-secret-keys --armor $keyid 2>/dev/null)
    if test -z "$armor"
        log_error "Could not export key: $keyid"
        log_error "Make sure the key exists: gpg --list-secret-keys"
        return 1
    end

    # Generate name from email if not provided
    if test -z "$name"
        set -l email (gpg --list-keys $keyid 2>/dev/null | grep uid | head -1 | string match -r '<(.+)>' | tail -1)
        if test -n "$email"
            # Sanitize email for item name
            set name $SECRETS_GPG_PREFIX(string replace -a '@' '-' (string replace -a '.' '-' $email))
        else
            set name $SECRETS_GPG_PREFIX$keyid
        end
    end

    # Ensure prefix
    if not string match -q "$SECRETS_GPG_PREFIX*" $name
        set name $SECRETS_GPG_PREFIX$name
    end

    log_info "Adding: $name"
    bw_create_note $name "$armor"
    log_success "Added: $name"
end

function gpg_rm -a name
    # Remove GPG key from Bitwarden
    if test -z "$name"
        echo "Usage: secrets gpg rm <name>"
        return 1
    end

    bw_session || return 1

    # Find by name
    set -l id (_bw_get_item_id $name 2)
    if test -z "$id"
        log_error "Not found: $name"
        return 1
    end

    bw_delete_item $id
    log_success "Removed: $name"
end

function gpg_list
    # List GPG keys in Bitwarden
    bw_session || return 1

    echo "GPG keys in Bitwarden:"
    set -l keys (bw_list_notes $SECRETS_GPG_PREFIX)
    if test -z "$keys"
        echo "  (none)"
        return 0
    end

    for line in $keys
        set -l parts (string split \t $line)
        echo "  $parts[2]"
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

    echo $keys | grep -E "^sec|^uid" | while read line
        echo "  $line"
    end
end
