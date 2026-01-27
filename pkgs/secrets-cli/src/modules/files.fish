# File management via BW + Keyring + Symlinks
#
# Architecture:
#   - Secrets stored in tmpfs: $XDG_RUNTIME_DIR/secrets/<filename>
#   - Symlinks created from target paths -> tmpfs
#   - Keyring holds file contents for offline export
#   - BW item holds attachments + manifest (filename -> symlink target)
#
# Flow:
#   pull:   BW -> keyring -> tmpfs + symlinks
#   export: keyring -> tmpfs + symlinks (offline, runs on login)
#   sync:   tmpfs -> keyring + BW

set -g SECRETS_STORE_DIR "$SECRETS_RUNTIME_DIR/secrets"

function _manifest_get -a item_id
    # Read manifest from _manifest.json attachment
    set -l tmp (runtime_tmpfile "manifest")
    if bw_get_attachment $item_id "_manifest.json" $tmp 2>/dev/null
        and test -s $tmp
        cat $tmp
        runtime_shred_file $tmp
        return 0
    end
    runtime_shred_file $tmp 2>/dev/null
    echo "{}"
end

function _manifest_set -a item_id manifest
    # Write manifest as _manifest.json attachment
    # Delete existing _manifest.json attachment if present
    set -l item (_bw_run get item $item_id 2>/dev/null)
    set -l att_id (printf '%s' "$item" | jq -r '.attachments[]? | select(.fileName == "_manifest.json") | .id // empty')
    test -n "$att_id" && bw_delete_attachment $item_id $att_id 2>/dev/null

    # Write to temp file with exact name _manifest.json
    set -l tmpdir (mktemp -d -p $SECRETS_RUNTIME_DIR "manifest-XXXXXX")
    set -l tmp $tmpdir/_manifest.json
    printf '%s' "$manifest" > $tmp
    chmod 600 $tmp

    bw_create_attachment $item_id $tmp >/dev/null
    runtime_shred_file $tmp
    rmdir $tmpdir 2>/dev/null
end

function _expand_path -a path
    # Expand path variables
    set path (string replace -a '$HOME' $HOME $path)
    set path (string replace -a '$UID' (id -u) $path)
    set path (string replace -a '$XDG_RUNTIME_DIR' $SECRETS_RUNTIME_DIR $path)
    echo $path
end

function _ensure_store
    # Ensure secrets store directory exists
    mkdir -p $SECRETS_STORE_DIR
    chmod 700 $SECRETS_STORE_DIR
end

function _export_file -a filename dest
    # Export file to tmpfs and create symlink
    _ensure_store

    # Write to tmpfs store
    set -l store_path $SECRETS_STORE_DIR/$filename
    keyring_get_file $filename > $store_path
    chmod 600 $store_path

    # Create symlink at target location
    set -l target (_expand_path $dest)
    mkdir -p (dirname $target)

    # Remove existing file/symlink
    rm -f $target

    # Create symlink: target -> store
    ln -sf $store_path $target

    item_ok $filename "$target -> $store_path"
end

function files_pull
    # Pull from BW -> keyring -> tmpfs + symlinks
    bw_session || return 1

    set -l item (bw_get_item $SECRETS_FILES_ITEM)
    if test -z "$item"
        log_warn "Item not found: $SECRETS_FILES_ITEM"
        log_info "Create with: secrets files add <local_path> <target_path>"
        return 1
    end

    set -l item_id (printf '%s' "$item" | jq -r '.id')
    set -l manifest (_manifest_get $item_id)
    set -l attachments (printf '%s' "$item" | jq -r '.attachments[]? | select(.fileName != "_manifest.json") | .fileName // empty')

    if test -z "$attachments"
        log_info "No attachments in $SECRETS_FILES_ITEM"
        return 0
    end

    _ensure_store
    set -l pulled 0
    set -l failed 0

    for filename in $attachments
        set -l dest (printf '%s' "$manifest" | jq -r --arg f "$filename" '.[$f] // empty')

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

        # Store in keyring (pipe to preserve newlines)
        cat $tmp | keyring_store_file $filename
        runtime_shred_file $tmp

        # Export to tmpfs + create symlink
        _export_file $filename $dest

        set pulled (math $pulled + 1)
    end

    # Store manifest in keyring for offline export
    printf '%s' "$manifest" | keyring_store_file "_manifest"

    log_info "Pulled $pulled files to $SECRETS_STORE_DIR"
    test $failed -gt 0 && log_warn "Failed: $failed"
    return 0
end

function files_export
    # Export from keyring -> tmpfs + symlinks (offline, runs on login)
    set -l manifest (keyring_get_file "_manifest")
    if test -z "$manifest"
        log_warn "No manifest in keyring"
        log_info "Run 'secrets pull' first to populate keyring"
        return 1
    end

    _ensure_store
    set -l exported 0

    for filename in (printf '%s' "$manifest" | jq -r 'keys[]')
        set -l dest (printf '%s' "$manifest" | jq -r --arg f "$filename" '.[$f]')
        set -l content (keyring_get_file $filename)

        if test -z "$content"
            item_fail $filename "not in keyring"
            continue
        end

        # Export to tmpfs + create symlink
        _export_file $filename $dest

        set exported (math $exported + 1)
    end

    log_info "Exported $exported files to $SECRETS_STORE_DIR"
end

function files_push -a filename
    # Push from local -> BW
    # If filename provided, only push that file (fast)
    # Otherwise push all files (slow, full sync)
    bw_session || return 1

    set -l item (bw_get_item $SECRETS_FILES_ITEM)
    if test -z "$item"
        log_error "Item not found: $SECRETS_FILES_ITEM"
        log_info "Run 'secrets files add' first"
        return 1
    end

    set -l item_id (printf '%s' "$item" | jq -r '.id')

    # Single file push (fast path)
    if test -n "$filename"
        # Get content from store or keyring
        set -l content ""
        if test -f $SECRETS_STORE_DIR/$filename
            set content (cat $SECRETS_STORE_DIR/$filename)
        else
            set content (keyring_get_file $filename)
        end

        if test -z "$content"
            log_error "File not found in store or keyring: $filename"
            return 1
        end

        # Delete existing attachment for this file
        set -l att_id (printf '%s' "$item" | jq -r --arg f "$filename" '.attachments[]? | select(.fileName == $f) | .id // empty')
        test -n "$att_id" && bw_delete_attachment $item_id $att_id 2>/dev/null

        # Upload new version
        set -l tmpdir (mktemp -d -p $SECRETS_RUNTIME_DIR "push-XXXXXX")
        set -l tmp $tmpdir/$filename
        printf '%s' "$content" > $tmp
        chmod 600 $tmp

        if bw_create_attachment $item_id $tmp >/dev/null
            item_ok $filename "synced"
        else
            item_fail $filename "upload failed"
            runtime_shred_file $tmp
            rmdir $tmpdir 2>/dev/null
            return 1
        end

        runtime_shred_file $tmp
        rmdir $tmpdir 2>/dev/null
        bw_sync
        return 0
    end

    # Full push (all files)
    set -l manifest (keyring_get_file "_manifest")
    if test -z "$manifest"
        log_error "No manifest in keyring"
        log_info "Run 'secrets pull' or 'secrets files add' first"
        return 1
    end

    # Delete existing attachments (except _manifest.json)
    for att_id in (printf '%s' "$item" | jq -r '.attachments[]? | select(.fileName != "_manifest.json") | .id // empty')
        bw_delete_attachment $item_id $att_id 2>/dev/null
    end

    set -l synced 0
    set -l tmpdir (mktemp -d -p $SECRETS_RUNTIME_DIR "push-XXXXXX")

    for f in (printf '%s' "$manifest" | jq -r 'keys[]')
        set -l content ""
        if test -f $SECRETS_STORE_DIR/$f
            set content (cat $SECRETS_STORE_DIR/$f)
        else
            set content (keyring_get_file $f)
        end

        if test -z "$content"
            item_fail $f "not in store or keyring"
            continue
        end

        set -l tmp $tmpdir/$f
        printf '%s' "$content" > $tmp
        chmod 600 $tmp

        if bw_create_attachment $item_id $tmp >/dev/null
            item_ok $f "synced"
            set synced (math $synced + 1)
        else
            item_fail $f "upload failed"
        end

        runtime_shred_file $tmp
    end

    rmdir $tmpdir 2>/dev/null
    _manifest_set $item_id "$manifest"
    bw_sync
    log_info "Synced $synced files (local -> BW)"
end

function files_add -a src dest
    # Add a new file to BW
    if test -z "$src" -o -z "$dest"
        echo "Usage: secrets files add <local_path> <symlink_path>"
        echo ""
        echo "Files are stored in: \$XDG_RUNTIME_DIR/secrets/<filename>"
        echo "Symlinks are created at: <symlink_path> -> store"
        echo ""
        echo "Examples:"
        echo "  secrets files add ~/.kube/config '\$HOME/.kube/config'"
        echo "  secrets files add /tmp/keys.txt '\$XDG_RUNTIME_DIR/sops/keys.txt'"
        echo "  secrets files add /tmp/hosts.conf '\$HOME/.ssh/hosts.conf'"
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
            '{type: 2, name: $name, notes: "", secureNote: {type: 0}}' \
            | _bw_run encode | _bw_run create item | string collect)
        set item_id (printf '%s' "$created" | jq -r '.id')
    else
        set item_id (printf '%s' "$item" | jq -r '.id')
        set manifest (_manifest_get $item_id)
    end

    set -l filename (basename $src)

    # Store in keyring (pipe to preserve newlines)
    cat $src | keyring_store_file $filename

    # Upload attachment
    bw_create_attachment $item_id $src >/dev/null

    # Update manifest
    set manifest (printf '%s' "$manifest" | jq --arg f "$filename" --arg d "$dest" '. + {($f): $d}')

    # Update manifest attachment
    _manifest_set $item_id "$manifest"

    # Store manifest in keyring
    printf '%s' "$manifest" | keyring_store_file "_manifest"

    # Export immediately
    _export_file $filename $dest

    bw_sync
    log_success "Added: $filename (symlink: $dest)"
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

    set -l item_id (printf '%s' "$item" | jq -r '.id')
    set -l manifest (_manifest_get $item_id)

    # Get dest for symlink cleanup
    set -l dest (printf '%s' "$manifest" | jq -r --arg f "$filename" '.[$f] // empty')

    # Delete from keyring
    keyring_delete_file $filename

    # Delete from store
    rm -f $SECRETS_STORE_DIR/$filename

    # Delete symlink
    if test -n "$dest"
        set -l target (_expand_path $dest)
        rm -f $target
    end

    # Delete attachment
    set -l att_id (printf '%s' "$item" | jq -r --arg f "$filename" '.attachments[]? | select(.fileName == $f) | .id // empty')
    if test -n "$att_id"
        bw_delete_attachment $item_id $att_id
    end

    # Update manifest
    set manifest (printf '%s' "$manifest" | jq --arg f "$filename" 'del(.[$f])')

    # Update manifest attachment
    _manifest_set $item_id "$manifest"

    # Update manifest in keyring
    printf '%s' "$manifest" | keyring_store_file "_manifest"

    bw_sync
    log_success "Removed: $filename"
end

function files_rename -a oldname newname
    # Rename a file entry in BW (renames attachment + manifest key)
    if test -z "$oldname" -o -z "$newname"
        echo "Usage: secrets files rename <oldname> <newname>"
        return 1
    end

    bw_session || return 1

    set -l item (bw_get_item $SECRETS_FILES_ITEM)
    if test -z "$item"
        log_error "Item not found: $SECRETS_FILES_ITEM"
        return 1
    end

    set -l item_id (printf '%s' "$item" | jq -r '.id')
    set -l manifest (_manifest_get $item_id)

    # Check old name exists
    set -l dest (printf '%s' "$manifest" | jq -r --arg f "$oldname" '.[$f] // empty')
    if test -z "$dest"
        log_error "File not found in manifest: $oldname"
        return 1
    end

    # Get attachment ID
    set -l att_id (printf '%s' "$item" | jq -r --arg f "$oldname" '.attachments[]? | select(.fileName == $f) | .id // empty')
    if test -z "$att_id"
        log_error "Attachment not found: $oldname"
        return 1
    end

    # Download old attachment to temp
    set -l tmp (runtime_tmpfile "rename")
    if not bw_get_attachment $item_id "$oldname" $tmp
        runtime_shred_file $tmp
        log_error "Failed to download $oldname"
        return 1
    end

    # Delete old attachment
    bw_delete_attachment $item_id $att_id

    # Rename temp file and upload
    set -l tmp_new (runtime_tmpfile "$newname")
    mv $tmp $tmp_new
    bw_create_attachment $item_id $tmp_new >/dev/null
    runtime_shred_file $tmp_new

    # Update manifest: remove old key, add new key with same dest
    set manifest (printf '%s' "$manifest" | jq --arg old "$oldname" --arg new "$newname" --arg d "$dest" 'del(.[$old]) + {($new): $d}')

    # Update manifest attachment
    _manifest_set $item_id "$manifest"

    # Update keyring: copy content to new name, delete old
    set -l content (keyring_get_file $oldname)
    if test -n "$content"
        printf '%s' "$content" | keyring_store_file $newname
        keyring_delete_file $oldname
    end

    # Rename in store
    if test -f $SECRETS_STORE_DIR/$oldname
        mv $SECRETS_STORE_DIR/$oldname $SECRETS_STORE_DIR/$newname
    end

    # Update symlink to point to new store path
    set -l target (_expand_path $dest)
    rm -f $target
    ln -sf $SECRETS_STORE_DIR/$newname $target

    # Update manifest in keyring
    printf '%s' "$manifest" | keyring_store_file "_manifest"

    bw_sync
    log_success "Renamed: $oldname -> $newname"
end

function files_mv -a filename newdest
    # Change the symlink destination for a file in manifest
    if test -z "$filename" -o -z "$newdest"
        echo "Usage: secrets files mv <filename> <new_symlink_path>"
        echo ""
        echo "Changes where the symlink points to (the destination path in manifest)"
        echo ""
        echo "Examples:"
        echo "  secrets files mv config '\$HOME/.kube/config'"
        echo "  secrets files mv hosts.conf '\$HOME/.ssh/hosts.conf'"
        return 1
    end

    bw_session || return 1

    set -l item (bw_get_item $SECRETS_FILES_ITEM)
    if test -z "$item"
        log_error "Item not found: $SECRETS_FILES_ITEM"
        return 1
    end

    set -l item_id (printf '%s' "$item" | jq -r '.id')
    set -l manifest (_manifest_get $item_id)

    # Check file exists in manifest
    set -l olddest (printf '%s' "$manifest" | jq -r --arg f "$filename" '.[$f] // empty')
    if test -z "$olddest"
        log_error "File not found in manifest: $filename"
        return 1
    end

    # Remove old symlink
    set -l oldtarget (_expand_path $olddest)
    rm -f $oldtarget

    # Update manifest with new destination
    set manifest (printf '%s' "$manifest" | jq --arg f "$filename" --arg d "$newdest" '.[$f] = $d')

    # Update manifest attachment
    _manifest_set $item_id "$manifest"

    # Update manifest in keyring
    printf '%s' "$manifest" | keyring_store_file "_manifest"

    # Create new symlink
    _export_file $filename $newdest

    bw_sync
    log_success "Moved: $filename -> $newdest"
end

function files_list
    # List files in BW
    bw_session || return 1

    set -l item (bw_get_item $SECRETS_FILES_ITEM)
    if test -z "$item"
        echo "Files item: $SECRETS_FILES_ITEM (not found)"
        return 1
    end

    set -l item_id (printf '%s' "$item" | jq -r '.id')

    echo "Files in Bitwarden ($SECRETS_FILES_ITEM):"
    echo "  Store: \$XDG_RUNTIME_DIR/secrets/<filename>"
    echo ""
    _manifest_get $item_id | jq -r 'to_entries[] | "  \(.key) <- \(.value)"'
end

function files_status
    # Show file status
    set -l manifest (keyring_get_file "_manifest")
    if test -z "$manifest"
        echo "Files: (no manifest in keyring - run 'secrets pull' first)"
        return 1
    end

    echo "Files (store: $SECRETS_STORE_DIR):"
    for filename in (printf '%s' "$manifest" | jq -r 'keys[]')
        set -l dest (printf '%s' "$manifest" | jq -r --arg f "$filename" '.[$f]')
        set -l store_path $SECRETS_STORE_DIR/$filename
        set -l target (_expand_path $dest)

        echo -n "  $filename: "

        set -l status_parts

        # Check keyring
        set -l in_keyring (keyring_get_file $filename)
        test -n "$in_keyring" && set -a status_parts "keyring"

        # Check store
        test -f $store_path && set -a status_parts "store"

        # Check symlink
        if test -L $target
            if test (readlink $target) = $store_path
                set -a status_parts "symlink"
            else
                set -a status_parts "symlink(wrong)"
            end
        else if test -f $target
            set -a status_parts "file(not symlink)"
        end

        if test (count $status_parts) -gt 0
            echo (string join " + " $status_parts)
        else
            echo "missing"
        end
        echo "    -> $target"
    end
end
