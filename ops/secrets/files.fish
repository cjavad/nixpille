# File management via BW + Keyring
#
# BW item (nixpille-files-$USER) holds:
#   - notes: JSON manifest mapping filename → target path
#   - attachments: the actual files
#
# Keyring (service=nixpille) holds file contents locally
# Files are exported from keyring to tmpfs on login
#
# Flow:
#   pull:   BW → keyring + tmpfs
#   export: keyring → tmpfs (on login, no BW needed)
#   sync:   tmpfs → keyring + BW

set -l script_dir (dirname (status filename))
source $script_dir/lib/bw.fish
source $script_dir/lib/keyring.fish
source $script_dir/lib/runtime.fish

set -g FILES_ITEM "nixpille-files-$USER"
set -g FILES_SERVICE "nixpille"

function _expand_path -a path
    set path (string replace -a '$HOME' $HOME $path)
    set path (string replace -a '$UID' (id -u) $path)
    set path (string replace -a '$XDG_RUNTIME_DIR' (runtime_dir) $path)
    echo $path
end

function _file_to_keyring -a filename content
    # Store file content in keyring
    printf '%s' "$content" | secret-tool store --label "nixpille: $filename" service $FILES_SERVICE type $filename
end

function _file_from_keyring -a filename
    # Get file content from keyring
    secret-tool lookup service $FILES_SERVICE type $filename 2>/dev/null
end

function _file_delete_keyring -a filename
    secret-tool clear service $FILES_SERVICE type $filename 2>/dev/null
end

function files_pull
    # Pull from BW → keyring + tmpfs
    bw_session || return 1

    set -l item ($BW_CLI get item $FILES_ITEM 2>/dev/null)
    if test -z "$item"
        echo "Item not found: $FILES_ITEM"
        return 1
    end

    set -l item_id (echo $item | jq -r '.id')
    set -l manifest (echo $item | jq -r '.notes // "{}"')
    set -l attachments (echo $item | jq -r '.attachments[]?.fileName // empty')

    if test -z "$attachments"
        echo "No attachments"
        return 0
    end

    for filename in $attachments
        set -l dest (echo $manifest | jq -r --arg f "$filename" '.[$f] // empty')

        if test -z "$dest"
            echo "  $filename: no mapping, skipped"
            continue
        end

        # Download to temp
        set -l tmp (mktemp -p (runtime_dir))
        $BW_CLI get attachment "$filename" --itemid $item_id --output $tmp 2>/dev/null
        or begin
            rm -f $tmp
            echo "  $filename: download failed"
            continue
        end

        set -l content (cat $tmp)
        rm -f $tmp

        # Store in keyring
        _file_to_keyring $filename "$content"

        # Export to destination
        if test "$dest" = "keyring"
            # Special case: age key goes to sops keyring entry
            keyring_store sops age-key "SOPS Age Key" "$content"
            echo "  $filename → keyring (sops)"
        else
            set -l target (_expand_path $dest)
            mkdir -p (dirname $target)
            printf '%s' "$content" > $target
            chmod 600 $target
            echo "  $filename → keyring + $target"
        end
    end

    # Store manifest in keyring too
    _file_to_keyring "_manifest" "$manifest"
end

function files_export
    # Export from keyring → tmpfs (no BW needed, runs on login)
    set -l manifest (_file_from_keyring "_manifest")
    if test -z "$manifest"
        echo "No manifest in keyring"
        return 1
    end

    for filename in (echo $manifest | jq -r 'keys[]')
        set -l dest (echo $manifest | jq -r --arg f "$filename" '.[$f]')
        set -l content (_file_from_keyring $filename)

        if test -z "$content"
            echo "  $filename: not in keyring"
            continue
        end

        if test "$dest" = "keyring"
            # Age key - ensure it's in sops keyring
            keyring_store sops age-key "SOPS Age Key" "$content"
            echo "  $filename → keyring (sops)"
        else
            set -l target (_expand_path $dest)
            mkdir -p (dirname $target)
            printf '%s' "$content" > $target
            chmod 600 $target
            echo "  $filename → $target"
        end
    end
end

function files_sync
    # Sync from tmpfs → keyring + BW
    bw_session || return 1

    set -l item ($BW_CLI get item $FILES_ITEM 2>/dev/null)
    if test -z "$item"
        echo "No item to sync. Use 'add:file' first."
        return 1
    end

    set -l item_id (echo $item | jq -r '.id')
    set -l manifest (echo $item | jq -r '.notes // "{}"')
    set -l runtime (runtime_dir)

    # Delete existing attachments
    for att_id in (echo $item | jq -r '.attachments[]?.id // empty')
        $BW_CLI delete attachment $att_id --itemid $item_id 2>/dev/null
    end

    # Re-upload each file from local
    for filename in (echo $manifest | jq -r 'keys[]')
        set -l dest (echo $manifest | jq -r --arg f "$filename" '.[$f]')
        set -l content

        if test "$dest" = "keyring"
            set content (keyring_get sops age-key 2>/dev/null)
        else
            set -l src (_expand_path $dest)
            test -f $src && set content (cat $src)
        end

        if test -z "$content"
            echo "  $filename: source missing"
            continue
        end

        # Update keyring
        _file_to_keyring $filename "$content"

        # Upload to BW
        set -l tmp $runtime/$filename
        printf '%s' "$content" > $tmp
        $BW_CLI create attachment --file $tmp --itemid $item_id >/dev/null
        rm -f $tmp
        echo "  $filename → keyring + BW"
    end

    # Update manifest in keyring
    _file_to_keyring "_manifest" "$manifest"

    $BW_CLI sync
    echo "Done"
end

function files_add -a src dest
    if test -z "$src" -o -z "$dest"
        echo "Usage: files_add <local_path> <target_path>"
        echo "  files_add ~/.kube/config '\$XDG_RUNTIME_DIR/kube/config'"
        echo "  files_add ~/.config/sops/age/keys.txt keyring"
        return 1
    end

    set src (eval echo $src)
    test -f $src || begin; echo "File not found: $src"; return 1; end

    bw_session || return 1

    # Get or create item
    set -l item ($BW_CLI get item $FILES_ITEM 2>/dev/null)
    set -l item_id
    set -l manifest '{}'

    if test -z "$item"
        echo "Creating $FILES_ITEM..."
        set -l created (jq -n '{type: 2, name: "'$FILES_ITEM'", notes: "{}", secureNote: {type: 0}}' | $BW_CLI encode | $BW_CLI create item)
        set item_id (echo $created | jq -r '.id')
    else
        set item_id (echo $item | jq -r '.id')
        set manifest (echo $item | jq -r '.notes // "{}"')
    end

    set -l filename (basename $src)
    set -l content (cat $src)

    # Store in keyring
    _file_to_keyring $filename "$content"

    # Upload attachment
    $BW_CLI create attachment --file $src --itemid $item_id >/dev/null

    # Update manifest
    set manifest (echo $manifest | jq --arg f "$filename" --arg d "$dest" '. + {($f): $d}')
    echo '{}' | jq --arg notes "$manifest" '{notes: $notes}' | $BW_CLI encode | $BW_CLI edit item $item_id >/dev/null

    # Store manifest in keyring
    _file_to_keyring "_manifest" "$manifest"

    $BW_CLI sync
    echo "Added: $filename → $dest"
end

function files_rm -a filename
    if test -z "$filename"
        echo "Usage: files_rm <filename>"
        return 1
    end

    bw_session || return 1

    set -l item ($BW_CLI get item $FILES_ITEM 2>/dev/null)
    if test -z "$item"
        echo "Item not found: $FILES_ITEM"
        return 1
    end

    set -l item_id (echo $item | jq -r '.id')
    set -l manifest (echo $item | jq -r '.notes // "{}"')

    # Delete from keyring
    _file_delete_keyring $filename

    # Delete attachment
    set -l att_id (echo $item | jq -r --arg f "$filename" '.attachments[]? | select(.fileName == $f) | .id // empty')
    if test -n "$att_id"
        $BW_CLI delete attachment $att_id --itemid $item_id
    end

    # Update manifest
    set manifest (echo $manifest | jq --arg f "$filename" 'del(.[$f])')
    echo '{}' | jq --arg notes "$manifest" '{notes: $notes}' | $BW_CLI encode | $BW_CLI edit item $item_id >/dev/null

    # Update manifest in keyring
    _file_to_keyring "_manifest" "$manifest"

    $BW_CLI sync
    echo "Removed: $filename"
end

function files_list
    bw_session || return 1

    set -l item ($BW_CLI get item $FILES_ITEM 2>/dev/null)
    if test -z "$item"
        echo "Item not found: $FILES_ITEM"
        return 1
    end

    echo "Files:"
    echo $item | jq -r '.notes // "{}"' | jq -r 'to_entries[] | "  \(.key) → \(.value)"'
end

function files_status
    set -l manifest (_file_from_keyring "_manifest")
    if test -z "$manifest"
        echo "Files: (no manifest in keyring - run pull first)"
        return 1
    end

    echo "Files:"
    for filename in (echo $manifest | jq -r 'keys[]')
        set -l dest (echo $manifest | jq -r --arg f "$filename" '.[$f]')
        set -l in_keyring (_file_from_keyring $filename)

        if test "$dest" = "keyring"
            echo -n "  $filename → keyring: "
            test -n "$in_keyring" && echo "present" || echo "missing"
        else
            set -l target (_expand_path $dest)
            echo -n "  $filename → $target: "
            if test -n "$in_keyring"
                test -f $target && echo "keyring + tmpfs" || echo "keyring only"
            else
                echo "missing"
            end
        end
    end
end
