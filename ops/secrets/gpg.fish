# GPG key management: BW secure notes → GPG keyring

set -l script_dir (dirname (status filename))
source $script_dir/lib/bw.fish

# GPG keys are stored as secure notes with prefix "gpg-"
set -g GPG_PREFIX "gpg-"

function gpg_pull
    bw_session || return 1

    set -l keys (bw_list_notes $GPG_PREFIX)
    if test -z "$keys"
        echo "No GPG keys in BW"
        return 0
    end

    set -l imported 0

    for name in $keys
        set -l armor (bw_get $name 2>/dev/null)
        test -z "$armor" && continue

        echo $armor | gpg --batch --import 2>/dev/null
        and set imported (math $imported + 1)
        and echo "  $name"
    end

    echo "Imported $imported keys"
end

function gpg_add -a keyid name
    if test -z "$keyid"
        echo "Usage: gpg_add <keyid> [name]"
        echo "  gpg_add ABC123"
        echo "  gpg_add ABC123 gpg-work"
        return 1
    end

    bw_session || return 1

    # Export armored key
    set -l armor (gpg --export-secret-keys --armor $keyid 2>/dev/null)
    if test -z "$armor"
        echo "Could not export key: $keyid"
        return 1
    end

    # Generate name from email if not provided
    if test -z "$name"
        set -l email (gpg --list-keys $keyid 2>/dev/null | grep uid | head -1 | string match -r '<(.+)>' | tail -1)
        if test -n "$email"
            set name $GPG_PREFIX(string replace -a '@' '-' (string replace -a '.' '-' $email))
        else
            set name $GPG_PREFIX$keyid
        end
    end

    bw_create_note $name "$armor"
    echo "Added: $name"
end

function gpg_rm -a name
    if test -z "$name"
        echo "Usage: gpg_rm <name>"
        return 1
    end

    bw_session || return 1

    set -l item ($BW_CLI get item $name 2>/dev/null)
    if test -z "$item"
        echo "Not found: $name"
        return 1
    end

    set -l item_id (echo $item | jq -r '.id')
    $BW_CLI delete item $item_id
    $BW_CLI sync
    echo "Removed: $name"
end

function gpg_list
    bw_session || return 1
    echo "GPG keys:"
    bw_list_notes $GPG_PREFIX | while read name
        echo "  $name"
    end
end

function gpg_status
    echo "GPG Keyring:"
    gpg --list-secret-keys --keyid-format SHORT 2>/dev/null | grep -E "^sec|^uid" || echo "  (empty)"
end
