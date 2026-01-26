# File management via BW + Keyring
#
# BW item (nixpille-files-$USER) holds:
#   - notes: JSON manifest mapping filename -> target path
#   - attachments: the actual files
#
# Keyring (service=nixpille) holds file contents locally
# Files are exported from keyring to tmpfs on login
#
# Flow:
#   pull:   BW -> keyring + tmpfs/disk
#   export: keyring -> tmpfs/disk (offline, runs on login)
#   sync:   tmpfs/disk -> keyring + BW

function _expand_path -a path
    # Expand path variables
    set path (string replace -a '$HOME' $HOME $path)
    set path (string replace -a '$UID' (id -u) $path)
    set path (string replace -a '$XDG_RUNTIME_DIR' $SECRETS_RUNTIME_DIR $path)
    echo $path
end

function files_pull
    # Pull from BW -> keyring + filesystem
    bw_session || return 1

    set -l item (bw_get_item $SECRETS_FILES_ITEM)
    if test -z "$item"
        log_warn "Item not found: $SECRETS_FILES_ITEM"
        log_info "Create with: secrets files add <local_path> <target_path>"
        return 1
    end

    set -l item_id (echo $item | jq -r '.id')
    set -l manifest (echo $item | jq -r '.notes // "{}"')
    set -l attachments (echo $item | jq -r '.attachments[]?.fileName // empty')

    if test -z "$attachments"
        log_info "No attachments in $SECRETS_FILES_ITEM"
        return 0
    end

    set -l pulled 0
    set -l failed 0

    for filename in $attachments
        set -l dest (echo $manifest | jq -r --arg f "$filename" '.[$f] // empty')

        if test -z "$dest"
            item_skip $filename "no mapping in manifest"
            continue
        end

        # Download to temp file
        set -l tmp (runtime_tmpfile "bw-att")
        if not bw_get_attachment $item_id "$filename" $tmp
            runtime_shred_file $tmp
            item_fail $filename "download failed"
            set failed (math $failed + 1)
            continue
        end

        set -l content (cat $tmp)
        runtime_shred_file $tmp

        # Store in keyring
        keyring_store_file $filename "$content"

        # Export to destination
        if test "$dest" = "keyring"
            # Special case: age key goes to sops keyring entry
            keyring_store_age_key "$content"
            item_ok $filename "keyring (sops)"
        else
            set -l target (_expand_path $dest)
            mkdir -p (dirname $target)
            printf '%s' "$content" > $target
            chmod 600 $target
            item_ok $filename $target
        end

        set pulled (math $pulled + 1)
    end

    # Store manifest in keyring for offline export
    keyring_store_file "_manifest" "$manifest"

    log_info "Pulled $pulled files"
    test $failed -gt 0 && log_warn "Failed: $failed"
    return 0
end

function files_export
    # Export from keyring -> filesystem (offline, runs on login)
    set -l manifest (keyring_get_file "_manifest")
    if test -z "$manifest"
        log_warn "No manifest in keyring"
        log_info "Run 'secrets pull' first to populate keyring"
        return 1
    end

    set -l exported 0

    for filename in (echo $manifest | jq -r 'keys[]')
        set -l dest (echo $manifest | jq -r --arg f "$filename" '.[$f]')
        set -l content (keyring_get_file $filename)

        if test -z "$content"
            item_fail $filename "not in keyring"
            continue
        end

        if test "$dest" = "keyring"
            # Ensure age key is in sops keyring
            keyring_store_age_key "$content"
            item_ok $filename "keyring (sops)"
        else
            set -l target (_expand_path $dest)
            mkdir -p (dirname $target)
            printf '%s' "$content" > $target
            chmod 600 $target
            item_ok $filename $target
        end

        set exported (math $exported + 1)
    end

    log_info "Exported $exported files"
end

function files_sync
    # Sync from filesystem -> keyring + BW
    bw_session || return 1

    set -l item (bw_get_item $SECRETS_FILES_ITEM)
    if test -z "$item"
        log_error "Item not found: $SECRETS_FILES_ITEM"
        log_info "Use 'secrets files add' first"
        return 1
    end

    set -l item_id (echo $item | jq -r '.id')
    set -l manifest (echo $item | jq -r '.notes // "{}"')

    # Delete existing attachments
    for att_id in (echo $item | jq -r '.attachments[]?.id // empty')
        bw_delete_attachment $item_id $att_id 2>/dev/null
    end

    set -l synced 0

    # Re-upload each file
    for filename in (echo $manifest | jq -r 'keys[]')
        set -l dest (echo $manifest | jq -r --arg f "$filename" '.[$f]')
        set -l content ""

        if test "$dest" = "keyring"
            set content (keyring_get_age_key)
        else
            set -l src (_expand_path $dest)
            test -f $src && set content (cat $src)
        end

        if test -z "$content"
            item_fail $filename "source missing"
            continue
        end

        # Update keyring
        keyring_store_file $filename "$content"

        # Upload to BW
        set -l tmp $SECRETS_RUNTIME_DIR/$filename
        printf '%s' "$content" > $tmp
        bw_create_attachment $item_id $tmp >/dev/null
        rm -f $tmp

        item_ok $filename "synced"
        set synced (math $synced + 1)
    end

    # Update manifest in keyring
    keyring_store_file "_manifest" "$manifest"

    bw_sync
    log_info "Synced $synced files"
end

function files_add -a src dest
    # Add a new file to BW
    if test -z "$src" -o -z "$dest"
        echo "Usage: secrets files add <local_path> <target_path>"
        echo ""
        echo "Examples:"
        echo "  secrets files add ~/.kube/config '\$XDG_RUNTIME_DIR/kube/config'"
        echo "  secrets files add ~/.config/sops/age/keys.txt keyring"
        echo "  secrets files add ~/.ssh/hosts.conf '\$XDG_RUNTIME_DIR/ssh/hosts.conf'"
        return 1
    end

    # Expand source path
    set src (eval echo $src)
    assert_file $src "File not found: $src" || return 1

    bw_session || return 1

    # Get or create item
    set -l item (bw_get_item $SECRETS_FILES_ITEM)
    set -l item_id ""
    set -l manifest '{}'

    if test -z "$item"
        log_info "Creating $SECRETS_FILES_ITEM..."
        set -l created (jq -n --arg name "$SECRETS_FILES_ITEM" \
            '{type: 2, name: $name, notes: "{}", secureNote: {type: 0}}' \
            | _bw_run encode | _bw_run create item)
        set item_id (echo $created | jq -r '.id')
    else
        set item_id (echo $item | jq -r '.id')
        set manifest (echo $item | jq -r '.notes // "{}"')
    end

    set -l filename (basename $src)
    set -l content (cat $src)

    # Store in keyring
    keyring_store_file $filename "$content"

    # Upload attachment
    bw_create_attachment $item_id $src >/dev/null

    # Update manifest
    set manifest (echo $manifest | jq --arg f "$filename" --arg d "$dest" '. + {($f): $d}')

    # Update item notes with manifest
    echo '{}' | jq --arg notes "$manifest" '{notes: $notes}' \
        | _bw_run encode | _bw_run edit item $item_id >/dev/null

    # Store manifest in keyring
    keyring_store_file "_manifest" "$manifest"

    bw_sync
    log_success "Added: $filename -> $dest"
end

function files_rm -a filename
    # Remove a file from BW
    if test -z "$filename"
        echo "Usage: secrets files rm <filename>"
        return 1
    end

    bw_session || return 1

    set -l item (bw_get_item $SECRETS_FILES_ITEM)
    if test -z "$item"
        log_error "Item not found: $SECRETS_FILES_ITEM"
        return 1
    end

    set -l item_id (echo $item | jq -r '.id')
    set -l manifest (echo $item | jq -r '.notes // "{}"')

    # Delete from keyring
    keyring_delete_file $filename

    # Delete attachment
    set -l att_id (echo $item | jq -r --arg f "$filename" '.attachments[]? | select(.fileName == $f) | .id // empty')
    if test -n "$att_id"
        bw_delete_attachment $item_id $att_id
    end

    # Update manifest
    set manifest (echo $manifest | jq --arg f "$filename" 'del(.[$f])')

    # Update item
    echo '{}' | jq --arg notes "$manifest" '{notes: $notes}' \
        | _bw_run encode | _bw_run edit item $item_id >/dev/null

    # Update manifest in keyring
    keyring_store_file "_manifest" "$manifest"

    bw_sync
    log_success "Removed: $filename"
end

function files_list
    # List files in BW
    bw_session || return 1

    set -l item (bw_get_item $SECRETS_FILES_ITEM)
    if test -z "$item"
        echo "Files item: $SECRETS_FILES_ITEM (not found)"
        return 1
    end

    echo "Files in Bitwarden ($SECRETS_FILES_ITEM):"
    echo $item | jq -r '.notes // "{}"' | jq -r 'to_entries[] | "  \(.key) -> \(.value)"'
end

function files_status
    # Show file status
    set -l manifest (keyring_get_file "_manifest")
    if test -z "$manifest"
        echo "Files: (no manifest in keyring - run 'secrets pull' first)"
        return 1
    end

    echo "Files:"
    for filename in (echo $manifest | jq -r 'keys[]')
        set -l dest (echo $manifest | jq -r --arg f "$filename" '.[$f]')
        set -l in_keyring (keyring_get_file $filename)

        if test "$dest" = "keyring"
            echo -n "  $filename -> keyring: "
            test -n "$in_keyring" && echo "present" || echo "missing"
        else
            set -l target (_expand_path $dest)
            echo -n "  $filename -> $target: "
            if test -n "$in_keyring"
                test -f $target && echo "keyring + fs" || echo "keyring only"
            else
                test -f $target && echo "fs only" || echo "missing"
            end
        end
    end
end
